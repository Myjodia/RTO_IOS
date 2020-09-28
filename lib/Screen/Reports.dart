import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:rto/ApiProvider/Apifile.dart';
import 'package:rto/Model/Transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Reports extends StatefulWidget {
  @override
  _ReportsState createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  bool sort;
  Future _subscriber;
  String uid, name, mobile, emailid;
  String title, msg, date, time, servicename, amount, status, transid;
  SharedPreferences prefs;
  List<Transactions> users = [];
  Razorpay _razorpay;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  _userdetails() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      uid = prefs.getString('uid');
      name = prefs.getString('name');
      mobile = prefs.getString('mobile');
      emailid = prefs.getString('email');

      FormData formData = FormData.fromMap({
        "user_uid": uid,
      });
      _subscriber = ApiFile().getTransResponse(formData);
      print(uid);
    });
  }

  @override
  void initState() {
    _userdetails();
    sort = false;
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    super.initState();
  }

  onSortColum(int columnIndex, bool ascending) {
    if (ascending) {
      users.sort((a, b) => a.formStatus.compareTo(b.formStatus));
    } else {
      users.sort((a, b) => b.formStatus.compareTo(a.formStatus));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        automaticallyImplyLeading: false,
        leading: Icon(Icons.report),
        title: new Text('Transaction'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: FutureBuilder<Transaction>(
            future: _subscriber,
            builder:
                (BuildContext context, AsyncSnapshot<Transaction> snapshot) {
              if (snapshot.connectionState == ConnectionState.none)
                return Container();
              else if (snapshot.connectionState == ConnectionState.waiting)
                return Container(
                    height: MediaQuery.of(context).size.height,
                    child: Center(
                        child: CupertinoActivityIndicator(
                      radius: 30,
                    )));
              print("data" + snapshot.data.transactions.toString());

              users = snapshot.data.transactions;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                    columnSpacing: 10,
                    sortAscending: sort,
                    sortColumnIndex: 4,
                    columns: [
                      DataColumn(
                          label: Text('Date\nTime',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 13))),
                      DataColumn(
                          label: Text('Payment',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 13))),
                      DataColumn(
                          tooltip: 'Service',
                          numeric: false,
                          label: Text('Service',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 13))),
                      DataColumn(
                          label: Text('Transaction id',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 13))),
                      DataColumn(
                          onSort: (columnIndex, ascending) {
                            setState(() {
                              sort = !sort;
                            });
                            onSortColum(columnIndex, ascending);
                          },
                          label: Text('Form Status',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 13)))
                    ],
                    rows: users
                        .map((user) => DataRow(cells: [
                              DataCell(Center(
                                child: Text(user.date + '\n' + user.time,
                                    style: TextStyle(fontSize: 11)),
                              )),
                              DataCell(
                                  Center(
                                    child: Text(user.payment,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: user.paymentStatus
                                                    .contains('Pending')
                                                ? Theme.of(context).primaryColor
                                                : Colors.green)),
                                  ), onTap: () {
                                setState(() {
                                  servicename =
                                      user.formName.replaceAll(',', '\n');
                                  amount = user.payment;
                                  transid = user.transactionalId;
                                });
                                _paymentdailog(
                                    user.transactionalId,
                                    user.paymentStatus.contains('Pending')
                                        ? 'Pending'
                                        : 'Thank You!',
                                    user.paymentStatus.contains('Pending')
                                        ? 'Your Payment is Pending'
                                        : 'Your transaction was successful',
                                    user.date,
                                    user.time,
                                    user.formStatus);
                              }),
                              DataCell(Text(user.formName.replaceAll(',', '\n'),
                                  style: TextStyle(
                                      fontSize: 9, color: Colors.amber))),
                              DataCell(Center(
                                child: Text(user.transactionalId,
                                    style: TextStyle(fontSize: 11)),
                              )),
                              DataCell(Center(
                                child: Text(user.formStatus,
                                    style: TextStyle(fontSize: 11)),
                              ))
                            ]))
                        .toList()),
              );
            }),
      ),
    );
  }

  _paymentdailog(transid, title, msg, date, time, status) {
    showDialog(
        // barrierColor: Theme.of(context).primaryColor,
        useSafeArea: true,
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Container(
                //   height: 50,
                //   decoration: new BoxDecoration(
                //       color: Theme.of(context).primaryColor,
                //       borderRadius: new BorderRadius.only(
                //           topLeft: const Radius.circular(15.0),
                //           topRight: const Radius.circular(15.0))),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: <Widget>[
                //       IconButton(
                //           icon: Icon(Icons.close, color: Colors.white),
                //           onPressed: () {
                //             Navigator.of(context).pop();
                //           }),
                //       Text(
                //         'Payment',
                //         style: TextStyle(
                //             color: Colors.white,
                //             fontSize: 18,
                //             fontWeight: FontWeight.bold),
                //       ),
                //     ],
                //   ),
                // ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(height: 10),
                    Text(
                      title,
                      style: TextStyle(
                          fontSize: 20,
                          color: title.contains('Pending')
                              ? Theme.of(context).primaryColor
                              : Colors.green),
                    ),
                    Text(
                      msg,
                      style: TextStyle(fontSize: 16),
                    ),
                    Divider(
                      color: Colors.black,
                    ),
                    Container(height: 5),
                    ListTile(
                      title: Text(
                        'DATE',
                      ),
                      subtitle: Text(date),
                      trailing: Column(
                        children: [
                          Text(
                            'TIME',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(time, style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                    ListTile(
                      title: Text('Service name'),
                      subtitle: Text(servicename),
                      trailing: Image.asset("assets/images/rto_image.png",
                          width: 30, height: 30),
                    ),
                    ListTile(
                      dense: true,
                      title: Text('AMOUNT'),
                      subtitle: Text(
                        amount,
                        style: TextStyle(fontSize: 20, color: Colors.black),
                      ),
                      trailing: Text(status),
                    ),
                    title.contains('Pending') || title.contains('Failed')
                        ? RaisedButton(
                            child: Text(
                              'Pay Now',
                              style: TextStyle(color: Colors.white),
                            ),
                            color: Theme.of(context).primaryColor,
                            onPressed: () {
                              Navigator.of(context).pop();
                              _scaffoldKey.currentState.showSnackBar(
                                  new SnackBar(
                                      content: Text(
                                          'Please Wait... we proceeding')));
                              _openCheckout(amount, servicename);
                            })
                        : Container(
                            height: 50,
                            child: Center(
                                child: Text('Transaction id : ' + transid)),
                          ),
                    Container(
                      height: 10,
                    )
                  ],
                ),
              ],
            ),
          );
        });
  }

  _paymenterrordailog() {
    showDialog(
        // barrierColor: Theme.of(context).primaryColor,
        useSafeArea: true,
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Container(
                //   height: 50,
                //   decoration: new BoxDecoration(
                //       color: Theme.of(context).primaryColor,
                //       borderRadius: new BorderRadius.only(
                //           topLeft: const Radius.circular(15.0),
                //           topRight: const Radius.circular(15.0))),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: <Widget>[
                //       IconButton(
                //           icon: Icon(Icons.close, color: Colors.white),
                //           onPressed: () {
                //             Navigator.of(context).pop();
                //           }),
                //       Text(
                //         'Payment',
                //         style: TextStyle(
                //             color: Colors.white,
                //             fontSize: 18,
                //             fontWeight: FontWeight.bold),
                //       ),
                //     ],
                //   ),
                // ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(height: 10),
                    Text(
                      'Failed',
                      style: TextStyle(
                          fontSize: 20,
                          color: title.contains('Pending')
                              ? Theme.of(context).primaryColor
                              : Colors.green),
                    ),
                    Text(
                      'Your payment failed try again!!',
                      style: TextStyle(fontSize: 16),
                    ),
                    Divider(
                      color: Colors.black,
                    ),
                    Container(height: 5),
                    ListTile(
                      title: Text(
                        'DATE',
                      ),
                      subtitle: Text(date),
                      trailing: Column(
                        children: [
                          Text(
                            'TIME',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(time, style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                    ListTile(
                      title: Text('Service name'),
                      subtitle: Text(servicename),
                      trailing: Image.asset("assets/images/rto_image.png",
                          width: 30, height: 30),
                    ),
                    ListTile(
                      dense: true,
                      title: Text('AMOUNT'),
                      subtitle: Text(
                        amount,
                        style: TextStyle(fontSize: 20, color: Colors.black),
                      ),
                      trailing: Column(
                        children: [
                          Text(status),
                        ],
                      ),
                    ),
                    title.contains('Pending') || title.contains('Failed')
                        ? RaisedButton(
                            child: Text(
                              'Pay Now',
                              style: TextStyle(color: Colors.white),
                            ),
                            color: Theme.of(context).primaryColor,
                            onPressed: () {
                              Navigator.of(context).pop();
                              _scaffoldKey.currentState.showSnackBar(
                                  new SnackBar(content: Text('Please Wait')));
                              _openCheckout(amount, servicename);
                            })
                        : Container(
                            height: 50,
                            child: Center(
                                child: Text('Transaction id : ' + transid)),
                          ),
                    Container(
                      height: 10,
                    )
                  ],
                ),
              ],
            ),
          );
        });
  }

  void _openCheckout(String amount, formname) async {
    print(amount);
    double payamount = (double.parse(amount) * 100);
    print(payamount);
    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag',
      'amount': payamount,
      'name': name,
      'description': formname,
      'prefill': {'contact': mobile, 'email': emailid},
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    var now = new DateTime.now();
    var currentdate = new DateFormat('dd-MM-yyyy');
    var currentime = new DateFormat.jm().format(now);
    String formattedDate = currentdate.format(now);
    _paymentdailog(response.paymentId, 'Thank You!',
        'Your transaction was successful', formattedDate, currentime, 'Sucess');
    FormData tformData = FormData.fromMap({
      "new_t_id": response.paymentId,
      "t_id": transid,
    });
    print(tformData.fields);
    final transresponse = await Dio()
        .post('https://rto24x7.com/api/payment_status/', data: tformData);

    Map<String, dynamic> user = jsonDecode(transresponse.data);
    if (user['result'] == 'Success') {
      setState(() {
        FormData formData = FormData.fromMap({
          "user_uid": uid,
        });
        _subscriber = ApiFile().getTransResponse(formData);
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _paymenterrordailog();
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _paymenterrordailog();
  }
}
