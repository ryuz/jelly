fn main () -> Result<(), Box<dyn std::error::Error>> {
    tonic_build::compile_protos("../protos/camera_control.proto")?;
    Ok(())
}
