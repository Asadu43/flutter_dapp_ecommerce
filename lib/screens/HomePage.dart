import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:web3dart/web3dart.dart';

import 'DetailScreen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _uri, account;
  SessionStatus? _session;
  var myData = BigInt.zero;
  late Client client;
  late Web3Client web3client;
  late DeployedContract contract;
  String? name;
  String? image;
  BigInt? price;
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

  Future<List<dynamic>> query(String name, List<dynamic> args) async {
    final contract = await loadContract();
    final ethFunction = contract.function(name);
    final result = await web3client.call(
        contract: contract, function: ethFunction, params: args);
    return result;
  }

  Future getTokenName() async {
    var response = await query("items", [BigInt.one]);
    name = response[1];
    image = response[3];
    price = response[4];
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    client = Client();
    web3client = Web3Client(rpc_url, client);
    getTokenName();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amberAccent,
        title: Text("E-Commerce App"),
      ),
      body: GridView.builder(
        itemCount: 10,
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DetailScreen(
                            name!,
                            image!,
                            price!,
                          )));
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Image.network(
                      image ??
                          "https://th.bing.com/th/id/R.3e77a1db6bb25f0feb27c95e05a7bc57?rik=DswMYVRRQEHbjQ&riu=http%3a%2f%2fwww.coalitionrc.com%2fwp-content%2fuploads%2f2017%2f01%2fplaceholder.jpg&ehk=AbGRPPcgHhziWn1sygs8UIL6XIb1HLfHjgPyljdQrDY%3d&risl=&pid=ImgRaw&r=0",
                      fit: BoxFit.cover,
                      height: 120),
                  Text(name ?? ""),
                  Text(
                      "${EtherAmount.inWei(price ?? BigInt.zero).getInEther} ETH")
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
