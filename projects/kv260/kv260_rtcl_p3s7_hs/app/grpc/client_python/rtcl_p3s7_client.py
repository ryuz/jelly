import grpc
from grpc.tools import protoc

# Ensure generated protobuf modules are available; if not, run protoc to generate them.
try:
    import rtcl_p3s7_control_pb2
    import rtcl_p3s7_control_pb2_grpc
except Exception:
    protoc.main((
        '',
        '-I../protos',
        '--python_out=.',
        '--grpc_python_out=.',
        'rtcl_p3s7_control.proto'
    ))
    import rtcl_p3s7_control_pb2
    import rtcl_p3s7_control_pb2_grpc


# Register and system constants
CAMREG_CORE_ID              = 0x0000
CAMREG_CORE_VERSION         = 0x0001
CAMREG_SENSOR_ENABLE        = 0x0004
CAMREG_SENSOR_READY         = 0x0008
CAMREG_RECV_RESET           = 0x0010
CAMREG_ALIGN_RESET          = 0x0020
CAMREG_ALIGN_PATTERN        = 0x0022
CAMREG_ALIGN_STATUS         = 0x0028
CAMREG_DPHY_CORE_RESET      = 0x0080
CAMREG_DPHY_SYS_RESET       = 0x0081
CAMREG_DPHY_INIT_DONE       = 0x0088

SYSREG_ID                   = 0x0000
SYSREG_DPHY_SW_RESET        = 0x0001
SYSREG_CAM_ENABLE           = 0x0002
SYSREG_CSI_DATA_TYPE        = 0x0003
SYSREG_DPHY_INIT_DONE       = 0x0004
SYSREG_FPS_COUNT            = 0x0006
SYSREG_FRAME_COUNT          = 0x0007
SYSREG_IMAGE_WIDTH          = 0x0008
SYSREG_IMAGE_HEIGHT         = 0x0009
SYSREG_BLACK_WIDTH          = 0x000a
SYSREG_BLACK_HEIGHT         = 0x000b

TIMGENREG_CORE_ID           = 0x0000
TIMGENREG_CORE_VERSION      = 0x0001
TIMGENREG_CTL_CONTROL       = 0x0004
TIMGENREG_CTL_STATUS        = 0x0005
TIMGENREG_CTL_TIMER         = 0x0008
TIMGENREG_PARAM_PERIOD      = 0x0010
TIMGENREG_PARAM_TRIG0_START = 0x0020
TIMGENREG_PARAM_TRIG0_END   = 0x0021
TIMGENREG_PARAM_TRIG0_POL   = 0x0022


class RtclP3s7Client:
    """gRPC client wrapper for rtcl_p3s7_control service.

    Provides the register and image helper methods previously defined
    as module-level functions in `rtcl_p3s7_control.py`.
    """

    def __init__(self, address='192.168.16.1:50051'):
        self.channel = grpc.insecure_channel(address)
        self.stub = rtcl_p3s7_control_pb2_grpc.RtclP3s7ControlStub(self.channel)

    def write_sys_reg(self, addr, data):
        self.stub.WriteSysReg(rtcl_p3s7_control_pb2.WriteRegRequest(addr=addr, data=data))

    def read_sys_reg(self, addr):
        res = self.stub.ReadSysReg(rtcl_p3s7_control_pb2.ReadRegRequest(addr=addr))
        return res.data

    def write_timgen_reg(self, addr, data):
        self.stub.WriteTimgenReg(rtcl_p3s7_control_pb2.WriteRegRequest(addr=addr, data=data))

    def read_timgen_reg(self, addr):
        res = self.stub.ReadTimgenReg(rtcl_p3s7_control_pb2.ReadRegRequest(addr=addr))
        return res.data

    def write_cam_reg(self, addr, data):
        self.stub.WriteCamReg(rtcl_p3s7_control_pb2.WriteRegRequest(addr=addr, data=data))

    def read_cam_reg(self, addr):
        res = self.stub.ReadCamReg(rtcl_p3s7_control_pb2.ReadRegRequest(addr=addr))
        return res.data

    def write_sensor_reg(self, addr, data):
        self.stub.WriteSensorReg(rtcl_p3s7_control_pb2.WriteRegRequest(addr=addr, data=data))

    def read_sensor_reg(self, addr):
        res = self.stub.ReadSensorReg(rtcl_p3s7_control_pb2.ReadRegRequest(addr=addr))
        return res.data

    def record_image(self, width, height, frames):
        self.stub.RecordImage(rtcl_p3s7_control_pb2.RecordImageRequest(width=width, height=height, frames=frames))

    def read_image(self, addr, size):
        res = self.stub.ReadImage(rtcl_p3s7_control_pb2.ReadImageRequest(addr=addr, size=size))
        return res.image

    def record_black(self, width, height, frames):
        self.stub.RecordBlack(rtcl_p3s7_control_pb2.RecordImageRequest(width=width, height=height, frames=frames))

    def read_black(self, addr, size):
        res = self.stub.ReadBlack(rtcl_p3s7_control_pb2.ReadImageRequest(addr=addr, size=size))
        return res.image
