import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:rto/ApiProvider/Apifile.dart';
import 'package:rto/Model/pricemodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SingleFormClass extends StatefulWidget {
  final String title, img1, img2, textname, count;
  final bool image1, image2, iddocs, bpdocs, textbox, applicantcard;

  const SingleFormClass(
      {Key key,
      this.title,
      this.img1,
      this.img2,
      this.image1,
      this.image2,
      this.iddocs,
      this.bpdocs,
      this.textname,
      this.textbox,
      this.applicantcard,
      this.count})
      : super(key: key);

  @override
  _SingleFormClassState createState() => _SingleFormClassState();
}

class _SingleFormClassState extends State<SingleFormClass> {
  int selectedRadio;
  String _selectedbp;
  Future _price;
  final _applicantcontroller = new TextEditingController();
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  File image1file;
  File image2file;
  File bprooffile;
  File idcardfile;
  Razorpay _razorpay;
  String uid, name, mobile, emailid;
  SharedPreferences prefs;
  String uploadimg1, uploadimg2, uploadidcard, uploadbp;
  bool _loading = false;

  final List<String> _dropdownValues = [
    'Pan Card',
    'Birth Certificate',
    '10th Board Certificate',
    '12th Board Certificate',
    'LIC Certificate',
    'Leaving Certificate'
  ];

  setSelectedRadio(int val) {
    setState(() {
      selectedRadio = val;
    });
  }

  _getprice() async {
    prefs = await SharedPreferences.getInstance();

    setState(() {
      uid = prefs.getString('uid');
      name = prefs.getString('name');
      mobile = prefs.getString('mobile');
      emailid = prefs.getString('email');
    });

    FormData formData = FormData.fromMap({
      "state_name": 'Maharashtra',
      "form_name": widget.title,
      "count": widget.count,
    });
    _price = ApiFile().getprice(formData);
  }

  @override
  void initState() {
    _getprice();
    selectedRadio = 0;
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        shrinkWrap: true,
        children: <Widget>[
          widget.applicantcard ? _applicantcard() : Container(),
          widget.image1 ? _image1() : Container(),
          widget.image2 ? _image2() : Container(),
          widget.iddocs ? _identitycard() : Container(),
          widget.bpdocs ? _birthproofcard() : Container(),
          FutureBuilder<Pricemodel>(
              future: _price,
              builder:
                  (BuildContext context, AsyncSnapshot<Pricemodel> snapshot) {
                if (snapshot.connectionState == ConnectionState.none)
                  return Container();
                else if (snapshot.connectionState == ConnectionState.waiting)
                  return CupertinoActivityIndicator(radius: 30);

                return snapshot.data.price == 0 && snapshot.data.price == ''
                    ? Center(
                        child: Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: Text(
                          'fill data to calculate cost',
                          style:
                              TextStyle(color: Theme.of(context).primaryColor),
                        ),
                      ))
                    : _loading
                        ? CupertinoActivityIndicator()
                        : _submitbutton(snapshot.data.price);
              }),
        ],
      ),
    );
  }

  _submitbutton(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height / 15,
        child: RaisedButton(
          color: Theme.of(context).primaryColor,
          onPressed: () {
            if (widget.applicantcard) {
              if (_applicantcontroller.text == '') {
                _showtoast('Please enter customer no');
                return;
              }
            }
            if (widget.image1) {
              if (image1file == null) {
                _showtoast('select ' + widget.img1 + ' to proceed');
                return;
              }
            }
            if (widget.image2) {
              if (image2file == null) {
                _showtoast('select ' + widget.img2 + ' to proceed');
                return;
              }
            }
            if (widget.bpdocs) {
              if (bprooffile == null) {
                _showtoast('select birth proof to proceed');
                return;
              }
            }
            if (widget.iddocs) {
              if (idcardfile == null) {
                _showtoast('select id card to proceed');
                return;
              }
            }
            _postuploadfile(text);
          },
          shape: new RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5)),
          child: Text(
            'Pay ' + text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  _postuploadfile(String amount) async {
    if (widget.img1.contains('Upload Medical Doc')) {
      uploadimg1 = 'medical';
    }
    if (widget.img2.contains('Upload Medical Doc')) {
      uploadimg2 = 'medical';
    }
    if (widget.img1.contains('Learning License')) {
      uploadimg1 = 'learn_lic';
    }
    if (widget.img2.contains('Learning License')) {
      uploadimg2 = 'learn_lic';
    }
    if (widget.img1.contains('Upload Motor License')) {
      uploadimg1 = 'motor_dri_lic';
    }
    if (widget.img2.contains('Upload Motor License')) {
      uploadimg2 = 'motor_dri_lic';
    }
    _uploaddata(amount);
  }

  _uploaddata(String amount) async {
    FormData formData = FormData.fromMap({
      "user_uid": uid,
      "customer_no": _applicantcontroller.text,
      uploadimg1: widget.image1
          ? await MultipartFile.fromFile(image1file.path,
              filename: image1file.path.split('/').last)
          : '',
      uploadimg2: widget.image2
          ? await MultipartFile.fromFile(image2file.path,
              filename: image2file.path.split('/').last)
          : '',
      "aadhar_voting": widget.iddocs
          ? await MultipartFile.fromFile(idcardfile.path,
              filename: idcardfile.path.split('/').last)
          : '',
      "birth_proof": widget.bpdocs
          ? await MultipartFile.fromFile(bprooffile.path,
              filename: bprooffile.path.split('/').last)
          : '',
    });
    print(formData.fields.toString());
    setState(() => _loading = true);
    final response = await Dio().post('https://rto24x7.com/api/form_new/',
        data: formData, onSendProgress: (int sent, int total) {});
    setState(() => _loading = false);

    response.statusCode == 200
        ? _openCheckout(amount)
        : _scaffoldKey.currentState
            .showSnackBar(new SnackBar(content: Text('Something went wrong')));
  }

  void _openCheckout(String amount) async {
    print(amount);
    int payamount = (int.parse(amount) * 100);
    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag',
      'amount': payamount,
      'name': name,
      'description': widget.title,
      'prefill': {'contact': mobile, 'email': emailid},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint(e);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _scaffoldKey.currentState.showSnackBar(
        new SnackBar(content: Text("SUCCESS: " + response.paymentId)));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
        content: Text(
            "ERROR: " + response.code.toString() + " - " + response.message)));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _scaffoldKey.currentState.showSnackBar(
        new SnackBar(content: Text("EXTERNAL_WALLET: " + response.walletName)));
  }

  _applicantcard() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 5),
      child: Card(
        elevation: 3,
        shadowColor: Theme.of(context).primaryColor,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Applicant Mobile Number',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic)),
              SizedBox(height: 10),
              TextField(
                controller: _applicantcontroller,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  WhitelistingTextInputFormatter.digitsOnly
                ],
                style: TextStyle(
                    color: Theme.of(context).primaryColor, fontSize: 15),
                decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(10),
                    enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor)),
                    focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor)),
                    hintText: 'Customer No.'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _image1() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 5),
      child: Card(
        elevation: 3,
        shadowColor: Theme.of(context).primaryColor,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(widget.img1,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic)),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    image1file != null
                        ? Image.file(
                            image1file,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            'assets/images/upload.png',
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                    FloatingActionButton.extended(
                      icon: Icon(Icons.file_upload),
                      heroTag: 0,
                      onPressed: () async {
                        print('Pick Image1');
                        showModalBottomSheet(
                            context: context,
                            builder: (BuildContext bc) {
                              return SafeArea(
                                child: Container(
                                  child: new Wrap(
                                    children: <Widget>[
                                      new ListTile(
                                          leading:
                                              new Icon(Icons.photo_library),
                                          title: new Text('Photo Library'),
                                          onTap: () async {
                                            Navigator.of(context).pop();
                                            final image = await ImagePicker()
                                                .getImage(
                                                    source: ImageSource.gallery,
                                                    imageQuality: 50);
                                            setState(() {
                                              image1file = File(image.path);
                                              print(image1file);
                                            });
                                          }),
                                      new ListTile(
                                        leading: new Icon(Icons.photo_camera),
                                        title: new Text('Camera'),
                                        onTap: () async {
                                          Navigator.of(context).pop();
                                          final image = await ImagePicker()
                                              .getImage(
                                                  source: ImageSource.camera,
                                                  imageQuality: 50);
                                          setState(() {
                                            image1file = File(image.path);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            });
                      },
                      label: Text('Pick'),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  _image2() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 5),
      child: Card(
        elevation: 3,
        shadowColor: Theme.of(context).primaryColor,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(widget.img2,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic)),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    image2file != null
                        ? Image.file(
                            image2file,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            'assets/images/upload.png',
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                    FloatingActionButton.extended(
                      icon: Icon(Icons.file_upload),
                      heroTag: null,
                      onPressed: () {
                        print('Pick Image2');
                        showModalBottomSheet(
                            context: context,
                            builder: (BuildContext bc) {
                              return SafeArea(
                                child: Container(
                                  child: new Wrap(
                                    children: <Widget>[
                                      new ListTile(
                                          leading:
                                              new Icon(Icons.photo_library),
                                          title: new Text('Photo Library'),
                                          onTap: () async {
                                            Navigator.of(context).pop();
                                            final image = await ImagePicker()
                                                .getImage(
                                                    source: ImageSource.gallery,
                                                    imageQuality: 50);
                                            setState(() {
                                              image2file = File(image.path);
                                              print(image2file);
                                            });
                                          }),
                                      new ListTile(
                                        leading: new Icon(Icons.photo_camera),
                                        title: new Text('Camera'),
                                        onTap: () async {
                                          Navigator.of(context).pop();
                                          final image = await ImagePicker()
                                              .getImage(
                                                  source: ImageSource.camera,
                                                  imageQuality: 50);
                                          setState(() {
                                            image2file = File(image.path);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            });
                      },
                      label: Text('Pick'),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  _identitycard() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 5),
      child: Card(
        elevation: 3,
        shadowColor: Theme.of(context).primaryColor,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Select Identification Document',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic)),
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 10, bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Column(children: <Widget>[
                      Row(children: <Widget>[
                        Radio(
                          value: 1,
                          groupValue: selectedRadio,
                          activeColor: Colors.green,
                          onChanged: (val) {
                            print("Radio $val");
                            setSelectedRadio(val);
                          },
                        ),
                        Text(
                          'Adhaar Card',
                          style: TextStyle(fontSize: 14),
                        )
                      ]),
                      Row(children: <Widget>[
                        Radio(
                          value: 2,
                          groupValue: selectedRadio,
                          activeColor: Colors.blue,
                          onChanged: (val) {
                            print("Radio $val");
                            setSelectedRadio(val);
                          },
                        ),
                        Text(
                          'Voting Card',
                          style: TextStyle(fontSize: 14),
                        )
                      ])
                    ]),
                    Column(
                      children: <Widget>[
                        selectedRadio == 0
                            ? Row(
                                children: <Widget>[
                                  Image.asset(
                                    'assets/images/aadharcard.png',
                                    height: 50,
                                    width: 50,
                                    fit: BoxFit.cover,
                                  ),
                                  Image.asset(
                                    'assets/images/voteridcard.png',
                                    height: 50,
                                    width: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ],
                              )
                            : idcardfile != null
                                ? Image.file(
                                    idcardfile,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    selectedRadio == 1
                                        ? 'assets/images/aadharcard.png'
                                        : 'assets/images/voteridcard.png',
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  ),
                        SizedBox(height: 10),
                        FloatingActionButton.extended(
                            icon: Icon(Icons.file_upload),
                            heroTag: null,
                            onPressed: () {
                              selectedRadio == 0
                                  ? _scaffoldKey.currentState.showSnackBar(
                                      new SnackBar(
                                          content: Text(
                                              "Please select first document!!")))
                                  : showModalBottomSheet(
                                      context: context,
                                      builder: (BuildContext bc) {
                                        return SafeArea(
                                          child: Container(
                                            child: new Wrap(
                                              children: <Widget>[
                                                new ListTile(
                                                    leading: new Icon(
                                                        Icons.photo_library),
                                                    title: new Text(
                                                        'Photo Library'),
                                                    onTap: () async {
                                                      Navigator.of(context)
                                                          .pop();
                                                      final image =
                                                          await ImagePicker()
                                                              .getImage(
                                                                  source:
                                                                      ImageSource
                                                                          .gallery,
                                                                  imageQuality:
                                                                      50);
                                                      setState(() {
                                                        idcardfile =
                                                            File(image.path);
                                                        print(idcardfile);
                                                      });
                                                    }),
                                                new ListTile(
                                                  leading: new Icon(
                                                      Icons.photo_camera),
                                                  title: new Text('Camera'),
                                                  onTap: () async {
                                                    Navigator.of(context).pop();
                                                    final image =
                                                        await ImagePicker()
                                                            .getImage(
                                                                source:
                                                                    ImageSource
                                                                        .camera,
                                                                imageQuality:
                                                                    50);
                                                    setState(() {
                                                      idcardfile =
                                                          File(image.path);
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      });
                            },
                            label: Text('Pick')),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _birthproofcard() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 5),
      child: Card(
        elevation: 3,
        shadowColor: Theme.of(context).primaryColor,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Choose Birth Proof Document',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic)),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                child: DropdownButtonHideUnderline(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: Colors.black26),
                    ),
                    child: DropdownButton(
                      items: _dropdownValues
                          .map((value) => DropdownMenuItem(
                                child: Text(value),
                                value: value,
                              ))
                          .toList(),
                      onChanged: (String value) {
                        setState(() {
                          _selectedbp = value;
                        });
                        print(_selectedbp);
                      },
                      value: _selectedbp,
                      isExpanded: true,
                      hint: Text('Select Birth Proof'),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      bprooffile != null
                          ? Image.file(
                              bprooffile,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              _selectedbp == null
                                  ? 'assets/images/upload.png'
                                  : _selectedbp.contains('Pan Card')
                                      ? 'assets/images/pancard.jpg'
                                      : _selectedbp
                                              .contains('Birth Certificate')
                                          ? 'assets/images/birthcertificate.jpeg'
                                          : _selectedbp.contains(
                                                  '10th Board Certificate')
                                              ? 'assets/images/ssc.png'
                                              : _selectedbp.contains(
                                                      '12th Board Certificate')
                                                  ? 'assets/images/mar.jpg'
                                                  : _selectedbp.contains(
                                                          'LIC Certificate')
                                                      ? 'assets/images/lic.jpg'
                                                      : 'assets/images/secondar.png',
                              height: 100,
                              width: 100,
                            ),
                      Text(
                          _selectedbp == null
                              ? 'Select Birth Proof'
                              : _selectedbp,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                  FloatingActionButton.extended(
                    icon: Icon(Icons.file_upload),
                    heroTag: null,
                    onPressed: () {
                      print('bp Pick Image');
                      _selectedbp == null
                          ? _scaffoldKey.currentState.showSnackBar(new SnackBar(
                              content: Text("Please select first document!!")))
                          : showModalBottomSheet(
                              context: context,
                              builder: (BuildContext bc) {
                                return SafeArea(
                                  child: Container(
                                    child: new Wrap(
                                      children: <Widget>[
                                        new ListTile(
                                            leading:
                                                new Icon(Icons.photo_library),
                                            title: new Text('Photo Library'),
                                            onTap: () async {
                                              Navigator.of(context).pop();
                                              final image = await ImagePicker()
                                                  .getImage(
                                                      source:
                                                          ImageSource.gallery,
                                                      imageQuality: 50);
                                              setState(() {
                                                bprooffile = File(image.path);
                                                print(bprooffile);
                                              });
                                            }),
                                        new ListTile(
                                          leading: new Icon(Icons.photo_camera),
                                          title: new Text('Camera'),
                                          onTap: () async {
                                            Navigator.of(context).pop();
                                            final image = await ImagePicker()
                                                .getImage(
                                                    source: ImageSource.camera,
                                                    imageQuality: 50);
                                            setState(() {
                                              bprooffile = File(image.path);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              });
                    },
                    label: Text('Pick'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _showtoast(String msg) {
    return _scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: Text(msg)));
  }
}
