Read this in other languages: [English](README.md), [日本語](README.ja.md)

# SiTCPXG_Sample_Code_for_KC705

KC705通信確認用のSiTCPXGサンプルソースコードです。

SiTCPXGの利用するAT93C46のインタフェースをKC705のEEPROM(M24C08)に変換するモジュールを使用しています。

また、KC705に搭載されているI2CスイッチPCA9548Aを動作させるモジュールも使用しています。

使用方法についてはPDFファイル（KC705_SiTCP_XG_EEPROM.pdf）をご確認ください。


## SiTCPXG とは

物理学実験での大容量データ転送を目的としてFPGA（Field Programmable Gate Array）上に実装されたシンプルなTCP/IPであるSiTCPの10GbE専用ライブラリです。

* SiTCP、SiTCPXGについては、[SiTCPライブラリページ](https://www.bbtech.co.jp/products/sitcp-library/)を参照してください。
* その他の関連プロジェクトは、[こちら](https://github.com/BeeBeansTechnologies)を参照してください。

![SiTCP](sitcp.png)


## 履歴

#### 2021-12-02 Ver.1.0.2

* SiTCPXGのディレクトリを削除

#### 2021-05-19 Ver.1.0.1

* KC705_SiTCP_XG_EEPROM.pdfを追加

#### 2021-04-02 Ver.1.0.0

* 新規登録。

