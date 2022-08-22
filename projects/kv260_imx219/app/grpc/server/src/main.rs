use tonic::{transport::Server, Request, Response, Status};
use camera_control::{OpenRequest, BoolResponse, camera_control_server::{CameraControl, CameraControlServer}};

pub mod camera_control {
  tonic::include_proto!("camera_control");
}


mod camera;


#[derive(Debug, Default)]
pub struct CameraControlService {

}

#[tonic::async_trait]
impl CameraControl for CameraControlService {
  async fn open(&self, request: Request<OpenRequest>) -> Result<Response<BoolResponse>, Status> {
    let r = request.into_inner();
    println!("open:{}", r.id);
    Ok(Response::new(camera_control::BoolResponse { result: true }))
  }
}


#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let ctl = camera::CameraControl::new();

//  let address = "[::1]:8080".parse().unwrap();
    let address = "0.0.0.0:8080".parse().unwrap();
    let camera_contro_service = CameraControlService::default();

  Server::builder().add_service(CameraControlServer::new(camera_contro_service))
    .serve(address)
    .await?;
  Ok(())
     
}


