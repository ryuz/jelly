
use tonic::{transport::Server, Request, Response, Status};

use rtcl_p3s7_control::rtcl_p3s7_control_server::{RtclP3s7Control, RtclP3s7ControlServer};
use rtcl_p3s7_control::{WriteRegRequest, BoolResponse};

mod rtcl_p3s7_i2c;
mod rtcl_p3s7_mng;

pub mod rtcl_p3s7_control {
    tonic::include_proto!("rtcl_p3s7_control"); // The string specified here must match the proto package name
}

#[derive(Debug, Default)]
pub struct RtclP3s7ControlService {
    verbose: i32,
}


#[tonic::async_trait]
impl RtclP3s7Control for RtclP3s7ControlService {
    async fn write_reg(&self, request: Request<WriteRegRequest>) -> Result<Response<BoolResponse>, Status> {
        let req = request.into_inner();
        if self.verbose >= 1 {
            println!("write_reg: addr={} data={}", req.addr, req.data);
        }
        Ok(Response::new(BoolResponse { result: true }))
    }
}


#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {

//  CAM_CTL.lock().unwrap().open()?;

    let address = "0.0.0.0:50051".parse().unwrap();
    let mut rtcl_p3s7_control_service = RtclP3s7ControlService::default();
    rtcl_p3s7_control_service.verbose = 1;

    Server::builder()
        .add_service(RtclP3s7ControlServer::new(rtcl_p3s7_control_service))
        .serve(address)
        .await?;

//  CAM_CTL.lock().unwrap().close();

    Ok(())
}
