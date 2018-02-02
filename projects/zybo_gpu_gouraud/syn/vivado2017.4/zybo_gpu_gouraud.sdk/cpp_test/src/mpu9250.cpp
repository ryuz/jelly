

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "sleep.h"
#include "xiicps.h"
#include "mpu9250.h"


// I2C parameters
#define IIC_SCLK_RATE       400000  // clock 400KHz
#define IIC_DEVICE_ID       XPAR_XIICPS_0_DEVICE_ID

#define MPU9250_ADDRESS		0x68    // 7bit address
#define AK8963_ADDRESS		0x0C	// Address of magnetometer

XIicPs Iic;

int i2c_write(XIicPs *Iic, u8 command, u16 i2c_adder)
{
    int Status;
    u8 buffer[4];
    buffer[0] = command;

    while(XIicPs_BusIsBusy(Iic)){
        /* NOP */
    }

    Status = XIicPs_MasterSendPolled(Iic, buffer, 1, i2c_adder);

    if(Status != XST_SUCCESS){
        return XST_FAILURE;
    }

    return XST_SUCCESS;
}


int i2c_read(XIicPs *Iic, u8* buff, u32 len, u16 i2c_adder)
{
    int Status;

    // Wait until bus is idle to start another transfer.
    while(XIicPs_BusIsBusy(Iic)){
        /* NOP */
    }

    Status = XIicPs_MasterRecvPolled(Iic, buff, len, i2c_adder);

    if (Status == XST_SUCCESS)
        return XST_SUCCESS;
    else
        return -1;
}



int Mpu9250_Init(void)
{
    int Status;
    XIicPs_Config *Config;  /**< configuration information for the device */

    Config = XIicPs_LookupConfig(IIC_DEVICE_ID);
    if(Config == NULL){
        printf("Error: XIicPs_LookupConfig()\n");
        return XST_FAILURE;
    }

    Status = XIicPs_CfgInitialize(&Iic, Config, Config->BaseAddress);
    if(Status != XST_SUCCESS){
        printf("Error: XIicPs_CfgInitialize()\n");
        return XST_FAILURE;
    }

    Status = XIicPs_SelfTest(&Iic);
    if(Status != XST_SUCCESS){
        printf("Error: XIicPs_SelfTest()\n");
        return XST_FAILURE;
    }

    XIicPs_SetSClk(&Iic, IIC_SCLK_RATE);
    printf("I2C configuration done.\n");

    // ì«Ç›èoÇµ
	u8    buff[16];
    i2c_write(&Iic, 0x75, MPU9250_ADDRESS);
    i2c_read(&Iic, buff, 1, MPU9250_ADDRESS);
    printf("WHO_AM_I:0x%02x\n\r", buff[0]);

    // ãNìÆ
    i2c_write(&Iic, 0x6b, MPU9250_ADDRESS);
    i2c_write(&Iic, 0x00, MPU9250_ADDRESS);

    i2c_write(&Iic, 0x37, MPU9250_ADDRESS);
    i2c_write(&Iic, 0x02, MPU9250_ADDRESS);

    return XST_SUCCESS;
}


bool Mpu9250_Read(Mpu9250Data& data)
{
	u8    buff[16];
    i2c_write(&Iic, 0x3b, MPU9250_ADDRESS);
    i2c_read(&Iic, buff, 14, MPU9250_ADDRESS);

    data.accel[0]    = (int)((short)((buff[ 0] << 8) | buff[ 1]));
    data.accel[1]    = (int)((short)((buff[ 2] << 8) | buff[ 3]));
    data.accel[2]    = (int)((short)((buff[ 4] << 8) | buff[ 5]));
    data.temperature = (int)((short)((buff[ 6] << 8) | buff[ 7]));
    data.gyro[0]     = (int)((short)((buff[ 8] << 8) | buff[ 9]));
    data.gyro[1]     = (int)((short)((buff[10] << 8) | buff[11]));
    data.gyro[2]     = (int)((short)((buff[12] << 8) | buff[13]));

    return true;
}


