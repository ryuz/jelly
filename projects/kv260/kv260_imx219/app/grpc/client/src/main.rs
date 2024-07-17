use camera_control::*;
use camera_control_client::CameraControlClient;
use tonic::transport::Channel;

pub mod camera_control {
    tonic::include_proto!("camera_control");
}

use std::fs::File;
use std::io::Write;


#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = std::env::args().collect();
    let target : String = if args.len() > 1 { args[1].clone() } else { "http://kria:50051".to_string() };
    println!("TARGET = {}", target);
    let mut client: CameraControlClient<Channel> = CameraControlClient::connect(target).await?;

    let request = tonic::Request::new(SetAoiRequest {
        id: 1,
        width: 640,
        height: 480,
        x: -1,
        y: -1,
    });
    let _response = client.set_aoi(request).await?;

    let request = tonic::Request::new(OpenRequest { id: 1 });
    let _response = client.open(request).await?;

    let request = tonic::Request::new(GetImageRequest { id: 1 });
    let img = client.get_image(request).await?;
    let img = img.into_inner();
    println!("width : {}", img.width);
    println!("height: {}", img.height);
    println!("len: {}", img.image.len());

    let mut file = File::create("camera_image.ppm")?;
    write!(file, "P3\n")?;
    write!(file, "{} {}\n", img.width, img.height)?;
    write!(file, "256\n")?;
    for i in 0..img.width * img.height {
        write!(file, "{} ", img.image[2 + 4 * i as usize])?;
        write!(file, "{} ", img.image[1 + 4 * i as usize])?;
        write!(file, "{}\n", img.image[0 + 4 * i as usize])?;
    }

    Ok(())
}
