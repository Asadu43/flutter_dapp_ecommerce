import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:web3dart/web3dart.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen(
    this.name,
    this.image,
    this.price, {
    Key? key,
  }) : super(key: key);
  final String name;
  final String image;
  final BigInt price;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  var _uri, account;
  SessionStatus? _session;
  var myData = BigInt.zero;
  late Client client;
  late Web3Client web3client;
  late DeployedContract contract;
  String contractAddress = "0x45d8131daaFF39059A8d788A813C51Cf11f444ED";
  final rpc_url =
      "https://goerli.infura.io/v3/4009a1b4ddf34fc6ad587c4b10dabe52";

  var connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      clientMeta: const PeerMeta(
          name: 'My App',
          description: 'An app for Connect with MetaMask and Send Transaction',
          url: 'https://walletconnect.org',
          icons: [
            'https://files.gitbook.com/v0/b/gitbook-legacy-files/o/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'
          ]));

  loginUsingMetamask(BuildContext context) async {
    if (!connector.connected) {
      try {
        var session = await connector.createSession(onDisplayUri: (uri) async {
          _uri = uri;
          await launchUrlString(uri, mode: LaunchMode.externalApplication);
          contract = await loadContract();
        });
        setState(() {
          _session = session;
          account = _session!.accounts[0];
        });
      } catch (exp) {
        print(exp);
      }
    }
  }

  Future<DeployedContract> loadContract() async {
    String abi = await rootBundle.loadString("assets/abi.json");
    final contract = DeployedContract(ContractAbi.fromJson(abi, "Dappazon"),
        EthereumAddress.fromHex(contractAddress));
    return contract;
  }

  Future buy(BuildContext context) async {
    var response = await submit("buy", [BigInt.one], context);
    return response;
  }

  submit(String name, List<dynamic> args, BuildContext context) async {
    if (connector.connected) {
      try {
        EthereumWalletConnectProvider provider =
            EthereumWalletConnectProvider(connector);
        await launchUrlString(_uri, mode: LaunchMode.externalApplication);
        final contract = await loadContract();
        var data = contract.function(name).encodeCall(args);

        var p = await web3client.estimateGas(
            to: EthereumAddress.fromHex(contractAddress),
            sender: EthereumAddress.fromHex(_session!.accounts[0]),
            data: data,
            value: EtherAmount.inWei(widget.price));

        var tx = await provider.sendTransaction(
          from: _session!.accounts[0],
          to: contractAddress,
          value: widget.price,
          gas: p.toInt(),
          data: data,
        );

        // TransactionReceipt? val = await web3client.getTransactionReceipt(tx);
        // if (val?.status == null) {
        //   AlertDialog alert = AlertDialog(
        //     content: Row(children: [
        //       const CircularProgressIndicator(
        //         backgroundColor: Colors.red,
        //       ),
        //       Container(
        //           margin: const EdgeInsets.only(left: 7),
        //           child: const Text("Please Wait")),
        //     ]),
        //   );
        //   showDialog(
        //     barrierDismissible: false,
        //     context: context,
        //     builder: (BuildContext context) {
        //       return alert;
        //     },
        //   );
        //   Future.delayed(const Duration(seconds: 15), () async {
        //     TransactionReceipt? value =
        //         await web3client.getTransactionReceipt(tx);
        //     if (value?.status != null) {
        //       Navigator.pop(context);
        //       // loadDialog(context, value!, tx);
        //     } else {
        //       Future.delayed(const Duration(seconds: 10), () async {
        //         TransactionReceipt? value =
        //             await web3client.getTransactionReceipt(tx);
        //         if (value?.status != null) {
        //           Navigator.pop(context);
        //           // loadDialog(context, value!, tx);
        //         }
        //       });
        //     }
        //   });
        // }
      } catch (exp) {
        print(exp);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please Connect with Metamask"),
      ));
      loginUsingMetamask(context);
    }
  }

  @override
  void initState() {
    super.initState();
    client = Client();
    web3client = Web3Client(rpc_url, client);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: Column(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Image.network(
              widget.image,
              fit: BoxFit.cover,
            ),
          ),
          Text(widget.name),
          Text("${EtherAmount.inWei(widget.price).getInEther} ETH"),
          ElevatedButton(
              onPressed: () {
                buy(context);
              },
              child: Text("Buy Now"))
        ],
      ),
    );
  }
}
