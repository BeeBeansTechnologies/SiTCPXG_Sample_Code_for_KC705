Read this in other languages: [English](README.md), [“ú–{Œê](README.ja.md)

# SiTCPXG_Sample_Code_for_KC705

This is the SiTCPXG sample source code for KC705 communication confirmation.

In this code use the module that converts the interface of AT93C46, used by SiTCPXG, to EEPROM (M24C08) of KC705.

This code also use a module that to operate I2C switch, PCA9548A, loaded on the KC705.

Please check the PDF file (KC705_SiTCP_XG_EEPROM.pdf) for how to use it.


## What is SiTCPXG

Simple TCP/IP implemented with support only for 10GbE on an FPGA (Field Programmable Gate Array) for the purpose of transferring large amounts of data in physics experiments.

* For details, please refer to [SiTCP Library page](https://www.bbtech.co.jp/en/products/sitcp-library/).
* For other related projects, please refer to [here](https://github.com/BeeBeansTechnologies).

![SiTCP](sitcp.png)


## History

#### 2021-04-02 Ver.1.0

* First release.
