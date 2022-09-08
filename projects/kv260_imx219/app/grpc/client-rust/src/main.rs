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
    println!("Hello, world!");
    let mut client: CameraControlClient<Channel> = CameraControlClient::connect("http://kria:50051").await?;

    let request = tonic::Request::new(SetAoiRequest {
        id: 1,
        width: 1280,
        height: 760,
        x: -1,
        y: -1,
    });
    let _response = client.set_aoi(request).await?;

    let request = tonic::Request::new(OpenRequest { id: 1 });
    let _response = client.open(request).await?;

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
            ).unwrap()
        };

        imshow("img", &img).unwrap();
        if wait_key(10).unwrap() > 0 { break;}
    }

    Ok(())
}

