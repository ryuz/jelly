use std::io::stdin;

use camera_control::{camera_control_client::CameraControlClient, OpenRequest};

pub mod camera_control {
  tonic::include_proto!("camera_control");
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
  let mut client = CameraControlClient::connect("http://127.0.0.1:8080").await?;
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
  Ok(())
}


/*
fn main() {
    println!("Hello, world!");
}
*/
