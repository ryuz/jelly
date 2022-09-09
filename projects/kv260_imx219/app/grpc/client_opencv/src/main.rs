use camera_control::*;
use camera_control_client::CameraControlClient;
use tonic::transport::Channel;

pub mod camera_control {
    tonic::include_proto!("camera_control");
}


use opencv::core::*;
//use opencv::imgcodecs::*;
use opencv::highgui::*;



#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("Start");

    let mut width:     i32 = 1280;
    let mut height:    i32 = 760;
    let mut framerate: i32 = 60;
    let mut exposure:  i32 = 33;
    let mut gain:      i32 = 10;

    let mut client: CameraControlClient<Channel> = CameraControlClient::connect("http://kria:50051").await?;

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
    create_trackbar("width",     &win_name, None, 2048, None)?; set_trackbar_min("framerate", &win_name, 4)?;
    create_trackbar("height",    &win_name, None, 2048, None)?; set_trackbar_min("framerate", &win_name, 4)?;
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
        let img = client.get_image(request).await?;
        let mut img = img.into_inner();

        let img= unsafe {
            Mat::new_rows_cols_with_data(
                img.height as i32,
                img.width as i32,
                CV_8UC4,
                img.image.as_mut_ptr() as *mut core::ffi::c_void,
                Mat_AUTO_STEP
            )?
        };

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

