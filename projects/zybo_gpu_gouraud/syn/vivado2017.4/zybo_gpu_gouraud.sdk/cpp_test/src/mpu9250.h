/*
 * mpu9250.h
 *
 *  Created on: 2018/02/02
 *      Author: ryuji2
 */

#ifndef SRC_MPU9250_H_
#define SRC_MPU9250_H_


struct Mpu9250Data
{
	int	accel[3];
	int	gyro[3];
	int	temperature;
};

int  Mpu9250_Init(void);
bool Mpu9250_Read(Mpu9250Data& data);

#endif /* SRC_MPU9250_H_ */
