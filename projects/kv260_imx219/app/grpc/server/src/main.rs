use camera_control::{
    camera_control_server::{CameraControl, CameraControlServer},
    Empty, BoolResponse, OpenRequest, ImageResponse,
};
use tonic::{transport::Server, Request, Response, Status};

pub mod camera_control {
    tonic::include_proto!("camera_control");
}

#[derive(Debug, Default)]
pub struct CameraControlService {}

mod camera;
use camera::CameraManager;

use once_cell::sync::Lazy;
use std::sync::Mutex;
static CAM_CTL: Lazy<Mutex<CameraManager>> = Lazy::new(|| Mutex::new(CameraManager::new()));

//impl CameraControlService {}

#[tonic::async_trait]
impl CameraControl for CameraControlService {
    async fn open(&self, request: Request<OpenRequest>) -> Result<Response<BoolResponse>, Status> {
        let r = request.into_inner();
        println!("open:{}", r.id);
        let result = match CAM_CTL.lock().unwrap().open() {Ok(_) => true, Err(_) => false};
        Ok(Response::new(BoolResponse { result: result }))
    }

    async fn close(&self, _request: Request<Empty>) -> Result<Response<BoolResponse>, Status> {
        println!("close");
        CAM_CTL.lock().unwrap().close();
        Ok(Response::new(BoolResponse { result: true }))
    }

    async fn get_image(&self, _request: Request<Empty>) -> Result<Response<ImageResponse>, Status> {
        println!("get_image");
        
        match CAM_CTL.lock().unwrap().get_image() {
            Ok(img) => {
                Ok(Response::new(ImageResponse { result: true, format: 1, width: 640, height: 460, image: img}))
            },
            Err(_) => {
                Ok(Response::new(ImageResponse { result: false, format: 0, width: 0, height: 0, image: vec![0u8; 0]}))
            },
        }
    }
}


#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {

    CAM_CTL.lock().unwrap().open()?;

    let address = "0.0.0.0:50051".parse().unwrap();
    let camera_contro_service = CameraControlService::default();

    Server::builder()
        .add_service(CameraControlServer::new(camera_contro_service))
        .serve(address)
        .await?;

    CAM_CTL.lock().unwrap().close();

    Ok(())
}
