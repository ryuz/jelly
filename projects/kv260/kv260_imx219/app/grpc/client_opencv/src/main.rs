use camera_control::*;
use camera_control_client::CameraControlClient;
use tonic::transport::Channel;

pub mod camera_control {
    tonic::include_proto!("camera_control");
}


use opencv::core::*;
//use opencv::imgcodecs::*;
use opencv::highgui::*;

use std::env;


#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("Start");
    println!("OpenCV : {}", opencv::core::CV_VERSION);

    let args: Vec<String> = env::args().collect();
    let target : String = if args.len() > 1 { args[1].clone() } else { "http://kria:50051".to_string() };
    println!("TARGET = {}", target);

    let mut width:     i32 = 1280;
    let mut height:    i32 = 760;
    let mut framerate: i32 = 60;
    let mut exposure:  i32 = 33;
    let mut gain:      i32 = 10;

    let mut client: CameraControlClient<Channel> = CameraControlClient::connect(target).await?;
    
    let request = tonic::Request::new(SetAoiRequest {
        id: 1,
        width: width,
        height: height,
        x: -1,
        y: -1,
    });
    let _response = client.set_aoi(request).await?;

    let request = tonic::Request::new(OpenRequest { id: 1 });
    let _response = client.open(request).await?;

    let win_name = "img";
    named_window("img", WINDOW_AUTOSIZE)?;
//  create_trackbar("gain", "img", Some(&mut gain), 20, None)?;
    create_trackbar("width",     &win_name, None, 2048, None)?; set_trackbar_min("width",     &win_name, 4)?;
    create_trackbar("height",    &win_name, None, 2048, None)?; set_trackbar_min("height",    &win_name, 4)?;
    create_trackbar("framerate", &win_name, None, 1000, None)?; set_trackbar_min("framerate", &win_name, 1)?;
    create_trackbar("exposure",  &win_name, None,  100, None)?;
    create_trackbar("gain",      &win_name, None,   20, None)?;

    set_trackbar_pos("width",     &win_name, width    )?;
    set_trackbar_pos("height",    &win_name, height   )?;
    set_trackbar_pos("framerate", &win_name, framerate)?;
    set_trackbar_pos("exposure",  &win_name, exposure )?;
    set_trackbar_pos("gain",      &win_name, gain     )?;

    loop {
        let request = tonic::Request::new(GetImageRequest { id: 1 });
        let image = client.get_image(request).await?;
        let image = image.into_inner();
        let w = image.width as i32;
        let h = image.height as i32;
        let img = Mat::new_rows_cols_with_data(h, w * 4,&image.image).unwrap();
        let img = img.reshape(4, height)?;
        imshow("img", &img)?;

        let new_width     = get_trackbar_pos("width",     &win_name)?;
        let new_height    = get_trackbar_pos("height",    &win_name)?;
        let new_framerate = get_trackbar_pos("framerate", &win_name)?;
        let new_exposure  = get_trackbar_pos("exposure",  &win_name)?;
        let new_gain      = get_trackbar_pos("gain",      &win_name)?;

        if new_width != width || new_height != height {
            width = new_width;
            height = new_height;
            let request = tonic::Request::new(SetAoiRequest {
                id: 1,
                width: width,
                height: height,
                x: -1,
                y: -1,
            });
            let _response = client.set_aoi(request).await?;
        }

        if new_framerate != framerate {
            framerate = new_framerate;
            let request = tonic::Request::new(SetFrameRateRequest {
                id: 1,
                frame_rate: framerate as f64,
            });
            let _response = client.set_frame_rate(request).await?;
        }

        if new_exposure != exposure {
            exposure = new_exposure;
            let request = tonic::Request::new(SetExposureTimeRequest { id: 1, exposure: exposure as f64 });
            client.set_exposure_time(request).await?;
        }

        if new_gain != gain {
            gain = new_gain;
            let request = tonic::Request::new(SetGainRequest { id: 1, gain: gain as f64 });
            client.set_gain(request).await?;
        }

        let key = wait_key(10)?;
        if key == 0x1b { break; }
    }

    Ok(())
}

