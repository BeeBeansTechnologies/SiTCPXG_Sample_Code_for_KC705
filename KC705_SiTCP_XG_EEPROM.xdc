#DIP SWはソースとボードで数字が反転している
#実機DIP SW4→ソースDIP SW0
set_property PACKAGE_PIN F16  [get_ports {GPIO_LED[7]}]
set_property PACKAGE_PIN E18  [get_ports {GPIO_LED[6]}]
set_property PACKAGE_PIN G19  [get_ports {GPIO_LED[5]}]
set_property PACKAGE_PIN AE26 [get_ports {GPIO_LED[4]}]
set_property PACKAGE_PIN AB9  [get_ports {GPIO_LED[3]}]
set_property PACKAGE_PIN AC9  [get_ports {GPIO_LED[2]}]
set_property PACKAGE_PIN AA8  [get_ports {GPIO_LED[1]}]
set_property PACKAGE_PIN AB8  [get_ports {GPIO_LED[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {GPIO_LED[3]}]
set_property IOSTANDARD LVCMOS15 [get_ports {GPIO_LED[2]}]
set_property IOSTANDARD LVCMOS15 [get_ports {GPIO_LED[1]}]
set_property IOSTANDARD LVCMOS15 [get_ports {GPIO_LED[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GPIO_LED[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GPIO_LED[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GPIO_LED[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GPIO_LED[4]}]
set_property PACKAGE_PIN Y28  [get_ports {GPIO_DIP_SW[3]}]
set_property PACKAGE_PIN AA28 [get_ports {GPIO_DIP_SW[2]}]
set_property PACKAGE_PIN W29  [get_ports {GPIO_DIP_SW[1]}]
set_property PACKAGE_PIN Y29  [get_ports {GPIO_DIP_SW[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GPIO_DIP_SW[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GPIO_DIP_SW[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GPIO_DIP_SW[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {GPIO_DIP_SW[0]}]
set_property PACKAGE_PIN AB7  [get_ports CPU_RESET]
set_property IOSTANDARD LVCMOS15 [get_ports CPU_RESET]

set_property PACKAGE_PIN J8 [get_ports SMA_MGT_REF_CLK_P]
set_property PACKAGE_PIN K28 [get_ports USER_CLOCK_P]
set_property PACKAGE_PIN Y23 [get_ports USER_SMA_GPIO_P]
set_property PACKAGE_PIN G4 [get_ports SFP_RX_P]

set_property PACKAGE_PIN Y20 [get_ports SFP_TX_DISABLE]
set_property IOSTANDARD LVCMOS25 [get_ports SFP_TX_DISABLE]

set_property IOSTANDARD LVCMOS15 [get_ports GPIO_SW_S]
set_property PACKAGE_PIN AB12 [get_ports GPIO_SW_S]

set_property IOSTANDARD LVCMOS25 [get_ports I2C_SDA]
set_property PACKAGE_PIN L21 [get_ports I2C_SDA]
set_property IOSTANDARD LVCMOS25 [get_ports I2C_SCL]
set_property PACKAGE_PIN K21 [get_ports I2C_SCL]



create_clock -period 6.400 [get_ports {USER_CLOCK_P}]

set_false_path -from [get_port CPU_RESET]
set_false_path -from [get_port GPIO_SW_S]
set_false_path -from [get_port {GPIO_DIP_SW*}]
set_false_path -to [get_port {GPIO_LED*}]
set_false_path -to [get_port SFP_TX_DISABLE]

set_min_delay -from [get_pins {AT93C46_IIC/PCA9548_SW/IIC_CTL/IIC_CORE/IIC_SCL_FD/C}] -to [get_port I2C_SCL]  0
set_max_delay -from [get_pins {AT93C46_IIC/PCA9548_SW/IIC_CTL/IIC_CORE/IIC_SCL_FD/C}] -to [get_port I2C_SCL]  -datapath_only 10
set_min_delay -from [get_pins {AT93C46_IIC/PCA9548_SW/IIC_CTL/IIC_CORE/IIC_SDA_OF/C}] -to [get_port I2C_SDA]  0
set_max_delay -from [get_pins {AT93C46_IIC/PCA9548_SW/IIC_CTL/IIC_CORE/IIC_SDA_OF/C}] -to [get_port I2C_SDA]  -datapath_only 10

set_property IOBDELAY NONE [get_nets AT93C46_IIC/PCA9548_SW/IIC_CTL/IIC_CORE/IB_SDA]
set_min_delay -from [get_port I2C_SDA]  -to [get_pins {AT93C46_IIC/PCA9548_SW/IIC_CTL/IIC_CORE/IIC_SDA_IF/D}] 0
set_max_delay -from [get_port I2C_SDA]  -to [get_pins {AT93C46_IIC/PCA9548_SW/IIC_CTL/IIC_CORE/IIC_SDA_IF/D}]  -datapath_only 5


set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
