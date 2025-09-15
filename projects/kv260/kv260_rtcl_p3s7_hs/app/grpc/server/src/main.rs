
use tonic::{transport::Server, Request, Response, Status};
use std::sync::{Arc, Mutex};

use rtcl_p3s7_control::rtcl_p3s7_control_server::{RtclP3s7Control, RtclP3s7ControlServer};
//use rtcl_p3s7_control::{WriteRegRequest, BoolResponse, ReadRegRequest, ReadRegResponse};
use rtcl_p3s7_control::*;

mod rtcl_p3s7_i2c;
mod rtcl_p3s7_mng;
use rtcl_p3s7_mng::RtclP3s7Mng;

pub mod rtcl_p3s7_control {
    tonic::include_proto!("rtcl_p3s7_control"); // The string specified here must match the proto package name
}

// #[derive(Debug, Default)]

pub struct RtclP3s7ControlService {
    verbose: i32,
    mng : Arc<Mutex<RtclP3s7Mng>>,
}


#[tonic::async_trait]
impl RtclP3s7Control for RtclP3s7ControlService {
    async fn write_sys_reg(&self, request: Request<WriteRegRequest>) -> Result<Response<BoolResponse>, Status> {
        let req = request.into_inner();
        let mut mng = self.mng.lock().unwrap();
        match mng.write_sys_reg(req.addr as usize, req.data as usize) {
            Ok(()) => {
                if self.verbose >= 1 {
                    println!("write_sys_reg: addr={} data={}", req.addr, req.data);
                }
                Ok(Response::new(BoolResponse { result: true }))
            }
            Err(e) => {
                if self.verbose >= 1 {
                    eprintln!("write_sys_reg failed for addr {}: {}", req.addr, e);
                }
                Ok(Response::new(BoolResponse { result: false }))
            }
        }
    }

    async fn read_sys_reg(&self, request: Request<ReadRegRequest>) -> Result<Response<ReadRegResponse>, Status> {
        let req = request.into_inner();
        let mut mng = self.mng.lock().unwrap();
        match mng.read_sys_reg(req.addr as usize) {
            Ok(data) => {
                if self.verbose >= 1 {
                    println!("read_sys_reg: addr={}", req.addr);
                }
                Ok(Response::new(ReadRegResponse { result: true, data: data as u64 }))
            }
            Err(e) => {
                if self.verbose >= 1 {
                    eprintln!("read_sys_reg failed for addr {}: {}", req.addr, e);
                }
                // On error return result=false and zero data
                Ok(Response::new(ReadRegResponse { result: false, data: 0 }))
            }
        }
    }

    async fn write_timgen_reg(&self, request: Request<WriteRegRequest>) -> Result<Response<BoolResponse>, Status> {
        let req = request.into_inner();
        let mut mng = self.mng.lock().unwrap();
        match mng.write_timgen_reg(req.addr as usize, req.data as usize) {
            Ok(()) => {
                if self.verbose >= 1 {
                    println!("write_timgen_reg: addr={} data={}", req.addr, req.data);
                }
                Ok(Response::new(BoolResponse { result: true }))
            }
            Err(e) => {
                if self.verbose >= 1 {
                    eprintln!("write_timgen_reg failed for addr {}: {}", req.addr, e);
                }
                Ok(Response::new(BoolResponse { result: false }))
            }
        }
    }

    async fn read_timgen_reg(&self, request: Request<ReadRegRequest>) -> Result<Response<ReadRegResponse>, Status> {
        let req = request.into_inner();
        let mut mng = self.mng.lock().unwrap();
        match mng.read_timgen_reg(req.addr as usize) {
            Ok(data) => {
                if self.verbose >= 1 {
                    println!("read_timgen_reg: addr={}", req.addr);
                }
                Ok(Response::new(ReadRegResponse { result: true, data: data as u64 }))
            }
            Err(e) => {
                if self.verbose >= 1 {
                    eprintln!("read_timgen_reg failed for addr {}: {}", req.addr, e);
                }
                // On error return result=false and zero data
                Ok(Response::new(ReadRegResponse { result: false, data: 0 }))
            }
        }
    }

    async fn write_cam_reg(&self, request: Request<WriteRegRequest>) -> Result<Response<BoolResponse>, Status> {
        let req = request.into_inner();
        let mut mng = self.mng.lock().unwrap();
        match mng.write_cam_reg(req.addr as u16, req.data as u16) {
            Ok(()) => {
                if self.verbose >= 1 {
                    println!("write_cam_reg: addr={} data={}", req.addr, req.data);
                }
                Ok(Response::new(BoolResponse { result: true }))
            }
            Err(e) => {
                if self.verbose >= 1 {
                    eprintln!("write_cam_reg failed for addr {}: {}", req.addr, e);
                }
                Ok(Response::new(BoolResponse { result: false }))
            }
        }
    }

    async fn read_cam_reg(&self, request: Request<ReadRegRequest>) -> Result<Response<ReadRegResponse>, Status> {
        let req = request.into_inner();
        let mut mng = self.mng.lock().unwrap();
        match mng.read_cam_reg(req.addr as u16) {
            Ok(data) => {
                if self.verbose >= 1 {
                    println!("read_cam_reg: addr={}", req.addr);
                }
                Ok(Response::new(ReadRegResponse { result: true, data: data as u64 }))
            }
            Err(e) => {
                if self.verbose >= 1 {
                    eprintln!("read_cam_reg failed for addr {}: {}", req.addr, e);
                }
                // On error return result=false and zero data
                Ok(Response::new(ReadRegResponse { result: false, data: 0 }))
            }
        }
    }

    async fn write_sensor_reg(&self, request: Request<WriteRegRequest>) -> Result<Response<BoolResponse>, Status> {
        let req = request.into_inner();
        let mut mng = self.mng.lock().unwrap();
        match mng.write_sensor_reg(req.addr as u16, req.data as u16) {
            Ok(()) => {
                if self.verbose >= 1 {
                    println!("write_sensor_reg: addr={} data={}", req.addr, req.data);
                }
                Ok(Response::new(BoolResponse { result: true }))
            }
            Err(e) => {
                if self.verbose >= 1 {
                    eprintln!("write_sensor_reg failed for addr {}: {}", req.addr, e);
                }
                Ok(Response::new(BoolResponse { result: false }))
            }
        }
    }

    async fn read_sensor_reg(&self, request: Request<ReadRegRequest>) -> Result<Response<ReadRegResponse>, Status> {
        let req = request.into_inner();
        let mut mng = self.mng.lock().unwrap();
        match mng.read_sensor_reg(req.addr as u16) {
            Ok(data) => {
                if self.verbose >= 1 {
                    println!("read_sensor_reg: addr={} data=>{}", req.addr, data);
                }
                Ok(Response::new(ReadRegResponse { result: true, data: data as u64 }))
            }
            Err(e) => {
                if self.verbose >= 1 {
                    eprintln!("read_sensor_reg failed for addr {}: {}", req.addr, e);
                }
                // On error return result=false and zero data
                Ok(Response::new(ReadRegResponse { result: false, data: 0 }))
            }
        }
    }

    async fn record_image(&self, request: Request<RecordImageRequest>) -> Result<Response<BoolResponse>, Status> {
        let req = request.into_inner();
        let mut mng = self.mng.lock().unwrap();
        match mng.record_image(req.width as usize, req.height as usize, req.frames as usize) {
            Ok(()) => {
                if self.verbose >= 1 {
                    println!("record_image: width={} height={} frames={}", req.width, req.height, req.frames);
                }
                Ok(Response::new(BoolResponse { result: true }))
            }
            Err(e) => {
                if self.verbose >= 1 {
                    eprintln!("record_image failed: {}", e);
                }
                Ok(Response::new(BoolResponse { result: false }))
            }
        }
    }

    async fn read_image(&self, request: Request<ReadImageRequest>) -> Result<Response<ReadImageResponse>, Status> {
        let req = request.into_inner();
        let mut mng = self.mng.lock().unwrap();
        match mng.read_image(req.addr as usize, req.size as usize) {
            Ok(buf) => {
                if self.verbose >= 1 {
                    println!("read_image: addr={} size={}", req.addr, req.size);
                }
                Ok(Response::new(ReadImageResponse { result: true, image: buf }))
            }
            Err(e) => {
                if self.verbose >= 1 {
                    eprintln!("read_image failed: {}", e);
                }
                // On error return empty data
                Ok(Response::new(ReadImageResponse { result: false, image: vec![] }))
            }
        }
    }

    async fn record_black(&self, request: Request<RecordImageRequest>) -> Result<Response<BoolResponse>, Status> {
        let req = request.into_inner();
        let mut mng = self.mng.lock().unwrap();
        match mng.record_black(req.width as usize, req.height as usize, req.frames as usize) {
            Ok(()) => {
                if self.verbose >= 1 {
                    println!("record_black: width={} height={} frames={}", req.width, req.height, req.frames);
                }
                Ok(Response::new(BoolResponse { result: true }))
            }
            Err(e) => {
                if self.verbose >= 1 {
                    eprintln!("record_black failed: {}", e);
                }
                Ok(Response::new(BoolResponse { result: false }))
            }
        }
    }

    async fn read_black(&self, request: Request<ReadImageRequest>) -> Result<Response<ReadImageResponse>, Status> {
        let req = request.into_inner();
        let mut mng = self.mng.lock().unwrap();
        match mng.read_black(req.addr as usize, req.size as usize) {
            Ok(buf) => {
                if self.verbose >= 1 {
                    println!("read_black: addr={} size={}", req.addr, req.size);
                }
                Ok(Response::new(ReadImageResponse { result: true, image: buf }))
            }
            Err(e) => {
                if self.verbose >= 1 {
                    eprintln!("read_black failed: {}", e);
                }
                // On error return empty data
                Ok(Response::new(ReadImageResponse { result: false, image: vec![] }))
            }
        }
    }
}


#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {

    println!("Starting RTCL P3S7 Control gRPC server...");
    let mng = Arc::new(Mutex::new(RtclP3s7Mng::new()?));

    let address = "0.0.0.0:50051".parse().unwrap();
    let rtcl_p3s7_control_service = RtclP3s7ControlService{
        verbose: 1,
        mng: mng,
    };

    Server::builder()
        .add_service(RtclP3s7ControlServer::new(rtcl_p3s7_control_service))
        .serve(address)
        .await?;

    Ok(())
}
