#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

use tokio::sync::Mutex;
//use std::sync::Mutex;
//use tauri::Manager;
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

/*
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
*/

async fn check_connect(cam_mng: &State<'_, CameraManager>) -> Result<(), ()> {
    let connect = cam_mng.lock().await;
    if connect.enable && connect.client.is_some() { Ok(()) } else { Err(()) }
}


#[tauri::command]
async fn connect(url: String, cam_mng: State<'_, CameraManager>) -> Result<(), ()> {
    let mut connect = cam_mng.lock().await;
    if connect.client.is_some() { Ok(()) } else {
        let connect_result = CameraControlClient::connect(url).await;
        match connect_result {
            Ok(client) => {
                connect.client = Some(client);
                connect.enable = true;
                Ok(())
            }
            _ => { Err(()) }
        }
    }
}

#[tauri::command]
async fn disconnect(cam_mng: State<'_, CameraManager>) -> Result<(), ()> {
    let mut connect = cam_mng.lock().await;
    connect.client = None;
    connect.enable = false;
    Ok(())
}

#[tauri::command]
async fn is_connect(cam_mng: State<'_, CameraManager>) -> Result<bool, ()> {
    let connect = cam_mng.lock().await;
    Ok(connect.enable && connect.client.is_some())
}


#[tauri::command]
async fn get_image(id: i32, cam_mng: State<'_, CameraManager>) -> Result<(i32, i32, String), ()> {
    let width: i32;
    let height: i32;
    let mut img = if check_connect(&cam_mng).await.is_ok() {
        // カメラ画像
        let mut connect = cam_mng.lock().await;
        let client = connect.client.as_mut().ok_or(())?;
        let request = tonic::Request::new(GetImageRequest { id: id });
        let img = client.get_image(request).await.or_else(|_| {connect.client = None; Err(())})?;
        let mut img = img.into_inner();
        width = img.width;
        height = img.height;
        let mat = unsafe { Mat::new_rows_cols_with_data(height, width, CV_8UC4, img.image.as_mut_ptr() as *mut std::os::raw::c_void, (img.width * 4) as usize).unwrap() };
        let mut img = Mat::default();
        cvt_color(&mat, &mut img, COLOR_BGRA2BGR, 0).unwrap();
        img
    }
    else {
        // ダミー画像
        width = 640;
        height = 480;
        let mut img = Mat::zeros(480, 640, CV_8UC3).unwrap().to_mat().unwrap();
        line(&mut img, Point::new(0, 0), Point::new(640, 480), Scalar::new(0., 0., 255., 255.), 5, LINE_8, 0).unwrap();
        line(&mut img, Point::new(640, 0), Point::new(0, 480), Scalar::new(0., 0., 255., 255.), 5, LINE_8, 0).unwrap();
        img
    };
    let mut buf = Vector::default();
    imencode(".png", &mut img, &mut buf, &Vector::default()).unwrap();
    let encode_bin : String = base64::encode(buf.to_vec());
    let encode_bin = format!("data:image/png;base64,{}", encode_bin);
    Ok((width, height, encode_bin))
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
async fn set_frame_rate(id: i32, frame_rate: f64,
    cam_mng: State<'_, CameraManager>) -> Result<(), ()>
{
    check_connect(&cam_mng).await?;
    let mut connect = cam_mng.lock().await;
    let client = connect.client.as_mut().ok_or(())?;

    let request = tonic::Request::new(SetFrameRateRequest {id: id, frame_rate: frame_rate});
    let res = client.set_frame_rate(request).await;
    if res.is_ok() { Ok(()) } else { Err(())}
}

#[tauri::command]
async fn set_exposure_time(id: i32, exposure: f64,
    cam_mng: State<'_, CameraManager>) -> Result<(), ()>
{
    check_connect(&cam_mng).await?;
    let mut connect = cam_mng.lock().await;
    let client = connect.client.as_mut().ok_or(())?;

    let request = tonic::Request::new(SetExposureTimeRequest {id: id, exposure: exposure});
    let res = client.set_exposure_time(request).await;
    if res.is_ok() { Ok(()) } else { Err(())}
}

#[tauri::command]
async fn set_gain(id: i32, gain: f64,
    cam_mng: State<'_, CameraManager>) -> Result<(), ()>
{
//    println!("set_gain");
    check_connect(&cam_mng).await?;
    let mut connect = cam_mng.lock().await;
    let client = connect.client.as_mut().ok_or(())?;

    let request = tonic::Request::new(SetGainRequest {id: id, gain: gain});
    let res = client.set_gain(request).await;
    if res.is_ok() { Ok(()) } else { Err(())}
}


#[tauri::command]
async fn set_digital_gain(id: i32, gain: f64,
    cam_mng: State<'_, CameraManager>) -> Result<(), ()>
{
    check_connect(&cam_mng).await?;
    let mut connect = cam_mng.lock().await;
    let client = connect.client.as_mut().ok_or(())?;

    let request = tonic::Request::new(SetGainRequest {id: id, gain: gain});
    let res = client.set_digital_gain(request).await;
    if res.is_ok() { Ok(()) } else { Err(())}
}


#[tauri::command]
async fn set_flip(id: i32, flip_h: bool, flip_v: bool,
    cam_mng: State<'_, CameraManager>) -> Result<(), ()>
{
    check_connect(&cam_mng).await?;
    let mut connect = cam_mng.lock().await;
    let client = connect.client.as_mut().ok_or(())?;

    let request = tonic::Request::new(SetFlipRequest {id: id, flip_h: flip_h, flip_v: flip_v});
    let res = client.set_flip(request).await;
    if res.is_ok() { Ok(()) } else { Err(())}
}

#[tauri::command]
async fn set_bayer_phase(id: i32, phase: i32,
    cam_mng: State<'_, CameraManager>) -> Result<(), ()>
{
    check_connect(&cam_mng).await?;
    let mut connect = cam_mng.lock().await;
    let client = connect.client.as_mut().ok_or(())?;

    let request = tonic::Request::new(SetBayerPhaseRequest {id: id, phase: phase});
    let res = client.set_bayer_phase(request).await;
    if res.is_ok() { Ok(()) } else { Err(())}
}


fn main() -> Result<(), Box<dyn std::error::Error>>  {
    println!("Start!!");
    println!("OpenCV : {}", opencv::core::CV_VERSION);

    let connection = Mutex::new(CameraConnect::new());
    tauri::Builder::default()
        .manage(connection)
        .invoke_handler(tauri::generate_handler![connect, disconnect, is_connect, get_image, set_aoi, set_frame_rate, set_exposure_time, set_gain, set_digital_gain, set_flip, set_bayer_phase])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
    
    Ok(())
}

