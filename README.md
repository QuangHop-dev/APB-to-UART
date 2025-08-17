# IP APB-UART
The APB-UART module acts as a bridge that enables communication between the APB and UART protocols. Its APB interface is implemented following the APB 4 specification. The bridge provides a total of five interrupt signals.
# Pin diagram of IP
Pin diagram of IP is showed below:
<img width="883" height="621" alt="image" src="https://github.com/user-attachments/assets/bef06c00-6501-4d52-9b99-e65babe55a1b" />
The signals PCLK and PRESET are provided by the system. The signals PSEL, PWRITE, PENABLE, PADDR, PWDATA, PSTRB, PPROT, PRDATA, PREADY, and PSLVERR are associated with the APB bus. Meanwhile, TXD and RXD are used to interface with the UART peripheral.  
*Detail of six interrupt signals:
| Name     | Description                                                  |
|----------|--------------------------------------------------------------|
| I_RXOV   | Overflow interrupt                                           |
| I_TXTHR  | Threshold of Transmitter interrupt                           |
| I_RXTHR  | Threshold of Receiver interrupt                              |
| I_FE     | Frame error of UART data interrupt                           |
| I_PE     | Parity error of UART data interrupt                          |
| I_TOTAL  | Total interrupt, high when any other interrupt signal is high |
# Registers of IP
There are total 4 registers in IP:
| Register Name | Type       | Width   | Address     | Description                                        |
|---------------|------------|---------|-------------|----------------------------------------------------|
| REG_DATA      | Read/Write | 8 bits  | 0x00000000  | Temporary storage register for data                |
| REG_BCLK      | Read/Write | 11 bits | 0x00000004  | Holds the BCLK configuration value                 |
| REG_EN        | Read/Write | 8 bits  | 0x00000008  | Contains enable control bits                       |
| REG_THR       | Read/Write | 4 bits  | 0x0000000C  | Defines threshold values for transmitter/receiver  |
# Setting baudrate and enable signals
## Setting Baudrate
The baudrate is calculated using the following formula:
BCLK_VAL = ClockFrequency / (Baudrate × 16)
### Parameters
- **BCLK_VAL**: The value that must be written into the BCLK register.  
- **ClockFrequency**: The system clock frequency.  
- **Baudrate**: The desired UART baudrate.  
### Example
If the system clock is **100 MHz** and the target baudrate is **9600**, then:
BCLK_VAL = 100,000,000 / (9600 × 16) = 651  
The value `651` should be written to **BCLK_REG**.
## Setting enable signals
There are 8 enables signal can be set:
| Register Name | Bit Position (REG_EN[7:0]) | Description                                      |
|---------------|-----------------------------|--------------------------------------------------|
| TXTHR_EN      | REG_EN[0]                  | Enables the transmitter threshold interrupt      |
| RXTHR_EN      | REG_EN[1]                  | Enables the receiver threshold interrupt         |
| RXOV_EN       | REG_EN[2]                  | Enables the receiver overflow interrupt          |
| PE_EN         | REG_EN[3]                  | Activates interrupt on parity error in receiver  |
| FE_EN         | REG_EN[4]                  | Activates interrupt on frame error in receiver   |
| IP_EN         | REG_EN[5]                  | Enables the IP operation                         |
| PARITY_EN     | REG_EN[6]                  | Enables transmit and receive data with parity    |
| PARITY_TYPE   | REG_EN[7]                  | Defines parity type: 0 = odd, 1 = even           |
# Testing IP
IP works properly with all 17 test cases:
| No. | Name                                                                 |
|-----|----------------------------------------------------------------------|
| 1   | Transmit data from APB to UART without parity                        |
| 2   | Transmit data from APB to UART with even parity                      |
| 3   | Transmit data from APB to UART with odd parity                       |
| 4   | Transmit 2 data packets from APB to UART without parity              |
| 5   | Receive data from UART to APB without parity                         |
| 6   | Receive data from UART to APB with even parity                       |
| 7   | Receive data from UART to APB with odd parity                        |
| 8   | Receive 2 data packets from UART to APB without parity               |
| 9   | Receive data from UART to APB without parity at a different baudrate |
| 10  | Transmit and receive data simultaneously                            |
| 11  | Handle fake start bit from UART                                      |
| 12  | Activate **I_TXTHR** signal                                          |
| 13  | Activate **I_RXTHR** signal                                          |
| 14  | Activate **I_RXOV** signal                                           |
| 15  | Activate **I_PE** signal                                             |
| 16  | Activate **I_FE** signal                                             |
| 17  | Activate **PSLVERR** signal                                          |
# Some images of result.
The enviroment testing is built with 100MHz for system frequency and 460800 for default baudrate (BCLK_VAL = 14).
There are some image of result:
## Trans data from APB to UART with no parity:
Setting enable signal, baudrate and data in APB interface:
<img width="1748" height="584" alt="image" src="https://github.com/user-attachments/assets/430424d2-eba7-4895-8aea-5f1cf98e942f" />
Result in TXD:
<img width="1463" height="549" alt="image" src="https://github.com/user-attachments/assets/a33c21cf-1f35-442c-988f-cdfce712e003" />
## Receive data from APB to UART with no parity:
Setting enable signal, baudrate:
<img width="1479" height="594" alt="image" src="https://github.com/user-attachments/assets/1f57024e-c5c3-4566-98f1-11711aa0e7ee" />
Data in RXD:
<img width="1500" height="641" alt="image" src="https://github.com/user-attachments/assets/add65337-f179-4019-bec2-07a20f066421" />
Read data in APB:
<img width="1476" height="715" alt="image" src="https://github.com/user-attachments/assets/4656ae36-67fb-4af0-a570-f3f15873f299" />
# Eviroment testing using UVM
This simulation environment is still under construction and will be completed in the future.
