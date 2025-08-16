fn main() -> Result<(), Box<dyn std::error::Error>> {
    tonic_prost_build::compile_protos("../protos/rtcl_p3s7_control.proto")?;
     /*
    tonic_prost_build::configure()
        .build_server(false)
        .compile_protos(
        &["../protos/rtcl_p3s7_control.proto"], &["../protos"])?;
    */
    Ok(())
}
