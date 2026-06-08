import 'package:firebase_auth/firebase_auth.dart';
class   AuthenticationService{
  final FirebaseAuth_auth = FirebaseAuth.instance;
  Future signInWithEmailAndPassword (String email, String password) async{
    try{

    }catch(exception){
      print(exception.toString());
      return null;
    }
  }
}