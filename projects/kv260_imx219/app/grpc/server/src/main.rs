/*
use camera_control::{
    camera_control_server::{CameraControl, CameraControlServer},
    Empty, BoolResponse, OpenRequest, ImageResponse,
};
*/
use camera_control::*;
use camera_control::camera_control_server::*;
use tonic::{transport::Server, Request, Response, Status};

pub mod camera_control {
    tonic::include_proto!("camera_control");
}

#[derive(Debug, Default)]
pub struct CameraControlService {
//    verbose : i32,
}

mod camera;
use camera::CameraManager;

use once_cell::sync::Lazy;
use std::sync::Mutex;
static CAM_CTL: Lazy<Mutex<CameraManager>> = Lazy::new(|| Mutex::new(CameraManager::new()));


#[tonic::async_trait]
impl CameraControl for CameraControlService {
    async fn open(&self, request: Request<OpenRequest>) -> Result<Response<BoolResponse>, Status> {
        let req = request.into_inner();
        println!("open:{}", req.id);
        let result = match CAM_CTL.lock().unwrap().open() {Ok(_) => true, Err(_) => false};
        Ok(Response::new(BoolResponse { result: result }))
    }

    async fn close(&self, request: Request<CloseRequest>) -> Result<Response<BoolResponse>, Status> {
        let req = request.into_inner();
        println!("close:{}", req.id);
        CAM_CTL.lock().unwrap().close();
        Ok(Response::new(BoolResponse { result: true }))
    }

    async fn is_opened(&self, _request: Request<IsOpenedRequest>) -> Result<Response<BoolResponse>, Status> {
        Ok(Response::new(BoolResponse { result: CAM_CTL.lock().unwrap().is_opened() }))
    }

    async fn get_image(&self, request: Request<GetImageRequest>) -> Result<Response<ImageResponse>, Status> {
        let req = request.into_inner();
        println!("get_image:{}", req.id);
        
        match CAM_CTL.lock().unwrap().get_image() {
            Ok((w, h, img)) => {
                Ok(Response::new(ImageResponse { result: true, format: 1, width: w, height: h, image: img}))
            },
            Err(_) => {
                Ok(Response::new(ImageResponse { result: false, format: 0, width: 0, height: 0, image: vec![0u8; 0]}))
            },
        }
    }

    async fn set_aoi(&self, request: Request<SetAoiRequest>) -> Result<Response<BoolResponse>, Status> {
        let req = request.into_inner();
        let result = match CAM_CTL.lock().unwrap().set_aoi(req.width, req.height, req.x, req.y) {Ok(_) => true, Err(_) => false};
        Ok(Response::new(BoolResponse { result: result }))
    }
    
    async fn set_frame_rate(&self, request: Request<SetFrameRateRequest>) -> Result<Response<BoolResponse>, Status> {
        let req = request.into_inner();
        let result = match CAM_CTL.lock().unwrap().set_frame_rate(req.frame_rate) {Ok(_) => true, Err(_) => false};
        Ok(Response::new(BoolResponse { result: result }))
    }

    async fn set_exposure_time(&self, request: Request<SetExposureTimeRequest>) -> Result<Response<BoolResponse>, Status> {
        let req = request.into_inner();
        let result = match CAM_CTL.lock().unwrap().set_exposure_time(req.exposure) {Ok(_) => true, Err(_) => false};
        Ok(Response::new(BoolResponse { result: result }))
    }

    async fn set_gain(&self, request: Request<SetGainRequest>) -> Result<Response<BoolResponse>, Status> {
        let req = request.into_inner();
        let result = match CAM_CTL.lock().unwrap().set_gain(req.gain) {Ok(_) => true, Err(_) => false};
        Ok(Response::new(BoolResponse { result: result }))
    }

    async fn set_digital_gain(&self, request: Request<SetGainRequest>) -> Result<Response<BoolResponse>, Status> {
        let req = request.into_inner();
        let result = match CAM_CTL.lock().unwrap().set_digital_gain(req.gain) {Ok(_) => true, Err(_) => false};
        Ok(Response::new(BoolResponse { result: result }))
    }

    async fn set_flip(&self, request: Request<SetFlipRequest>) -> Result<Response<BoolResponse>, Status> {
        let req = request.into_inner();
        let result = match CAM_CTL.lock().unwrap().set_flip(req.flip_h, req.flip_v) {Ok(_) => true, Err(_) => false};
        Ok(Response::new(BoolResponse { result: result }))
    }

    async fn set_bayer_phase(&self, request: Request<SetBayerPhaseRequest>) -> Result<Response<BoolResponse>, Status> {
        let req = request.into_inner();
        let result = match CAM_CTL.lock().unwrap().set_bayer_phase(req.phase) {Ok(_) => true, Err(_) => false};
        Ok(Response::new(BoolResponse { result: result }))
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
