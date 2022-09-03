use std::io::stdin;

use camera_control::{camera_control_client::CameraControlClient, OpenRequest, Empty, ImageResponse};

pub mod camera_control {
  tonic::include_proto!("camera_control");
}

use std::fs::File;
use std::io::{self, BufRead, Write, BufReader};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
// let mut client = CameraControlClient::connect("http://127.0.0.1:8080").await?;
   let mut client = CameraControlClient::connect("http://kria:50051").await?;
   /*
  loop {
    println!("\nPlease vote for a particular url");
    let mut u = String::new();
    let mut vote: String = String::new();
    println!("Please provide a url: ");
    stdin().read_line(&mut u).unwrap();
    let u = u.trim();
    println!("Please vote (d)own or (u)p: ");
    stdin().read_line(&mut vote).unwrap();
    let v = match vote.trim().to_lowercase().chars().next().unwrap() {
      'u' => 0,
      'd' => 1,
      _ => break,
    };
    let request = tonic::Request::new(OpenRequest {
      id: 1,
    });
    let response = client.open(request).await?;
//    println!("Got: '{}' from service", response.into_inner().confirmation);
  }
  */

  let request = tonic::Request::new(OpenRequest {id: 1,});
  let response = client.open(request).await?;
//    println!("Got: '{}' from service", response.into_inner().confirmation);

  let empty = tonic::Request::new(Empty{});
  let img = client.get_image(empty).await?;
  let img = img.into_inner();
  println!("width : {}", img.width);
  println!("height: {}", img.height);
  println!("len: {}", img.image.len());
  
  let mut file = File::create("test.ppm")?;
  write!(file, "P3\n")?;
  write!(file, "{} {}\n", img.width, img.height)?;
  write!(file, "256\n")?;
  for i in 0..img.width*img.height {
    write!(file, "{} ", img.image[2+4*i as usize])?;
    write!(file, "{} ", img.image[1+4*i as usize])?;
    write!(file, "{}\n", img.image[0+4*i as usize])?;
  }

  Ok(())
}


/*
fn main() {
    println!("Hello, world!");
}
*/
