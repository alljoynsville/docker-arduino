#!/usr/bin/env python3

import serial

sobj = serial.Serial(port='/dev/ttyACM0', baudrate=9600,timeout=0)
current_bytes_in_line = 0

while(True):
	buff = sobj.readline()
	if buff == b'STARTOFBUFF\r\n':
		print("__START_PACKET__")
		buff = sobj.readline()
		while buff != b'ENDOFBUFF\r\n':
			print(buff)
		print("__END_PACKET__")
			
			
