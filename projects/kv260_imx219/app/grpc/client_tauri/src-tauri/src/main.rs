#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

use tokio::sync::Mutex;
//use std::sync::Mutex;
use tauri::Manager;
use tauri::State;

use camera_control::*;
use camera_control_client::CameraControlClient;
use tonic::transport::Channel;

use opencv::core::*;
use opencv::imgcodecs::*;
use opencv::imgproc::*;


pub mod camera_control {
    tonic::include_proto!("camera_control");
}


struct CameraConnect {
    client: Option<CameraControlClient<Channel>>,
    enable: bool,
}

impl CameraConnect {
    pub fn new() -> Self {
        CameraConnect{ client:None, enable: false, }
    }
}

type CameraManager = Mutex<CameraConnect>;


async fn check_connect(cam_mng: &State<'_, CameraManager>) -> Result<(), ()> {
    let mut connect = cam_mng.lock().await;
    if connect.client.is_some() { Ok(()) } else {
        let connect_result = CameraControlClient::connect("http://kria:50051").await;
        match connect_result {
            Ok(client) => {
                connect.client = Some(client);
                Ok(())
            }
            _ => { Err(()) }
        }
    }
}

/*
async fn connect_error(cam_mng: &State<'_, CameraManager>) -> Err() {
    let mut connect = cam_mng.lock().await;
    connect.client = None;
    Err()
}*/


#[tauri::command]
async fn get_image(id: i32, cam_mng: State<'_, CameraManager>) -> Result<String, ()> {
    let mut img = if check_connect(&cam_mng).await.is_ok() {
        // カメラ画像
        let mut connect = cam_mng.lock().await;
        let client = connect.client.as_mut().ok_or(())?;
        let request = tonic::Request::new(GetImageRequest { id: id });
        let img = client.get_image(request).await.or_else(|_| {connect.client = None; Err(())})?;
        let mut img = img.into_inner();
        let mut mat = unsafe { Mat::new_rows_cols_with_data(img.height, img.width, CV_8UC4, img.image.as_mut_ptr() as *mut std::os::raw::c_void, (img.width * 4) as usize).unwrap() };
        let mut img = Mat::default();
        cvt_color(&mat, &mut img, COLOR_BGRA2BGR, 0).unwrap();
        img
    }
    else {
        // ダミー画像
        let mut img = Mat::zeros(480, 640, CV_8UC3).unwrap().to_mat().unwrap();
        line(&mut img, Point::new(0, 0), Point::new(640, 480), Scalar::new(0., 0., 255., 255.), 5, LINE_8, 0).unwrap();
        line(&mut img, Point::new(640, 0), Point::new(0, 480), Scalar::new(0., 0., 255., 255.), 5, LINE_8, 0).unwrap();
        img
    };
    let mut buf = Vector::default();
    imencode(".png", &mut img, &mut buf, &Vector::default()).unwrap();
    let encode_bin : String = base64::encode(buf.to_vec());
    let encode_bin = format!("data:image/png;base64,{}", encode_bin);
    Ok(encode_bin)
}



#[tauri::command]
async fn set_aoi(id: i32, width: i32, height: i32, x: i32, y: i32,
    cam_mng: State<'_, CameraManager>) -> Result<(), ()>
{
    println!("set_aoi");
    check_connect(&cam_mng).await?;
    let mut connect = cam_mng.lock().await;
    let client = connect.client.as_mut().ok_or(())?;

    let request = tonic::Request::new(SetAoiRequest {id: id, width:width, height:height, x:x, y:y});
    let res = client.set_aoi(request).await;
    if res.is_ok() { Ok(()) } else { Err(())}
}

#[tauri::command]
async fn set_gain(id: i32, gain: f64,
    cam_mng: State<'_, CameraManager>) -> Result<(), ()>
{
    println!("set_gain");
    check_connect(&cam_mng).await?;
    let mut connect = cam_mng.lock().await;
    let client = connect.client.as_mut().ok_or(())?;

    let request = tonic::Request::new(SetGainRequest {id: id, gain: gain});
    let res = client.set_gain(request).await;
    if res.is_ok() { Ok(()) } else { Err(())}
}


fn main() -> Result<(), Box<dyn std::error::Error>>  {
    println!("Start!!");

    let connection = Mutex::new(CameraConnect::new());
    tauri::Builder::default()
        .manage(connection)
        .invoke_handler(tauri::generate_handler![get_image, set_aoi, set_gain])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
    
    Ok(())
}

