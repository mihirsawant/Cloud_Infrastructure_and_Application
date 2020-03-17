const express=require("express");
const router=express.Router();
const app=require("../../app");
//const metrics=require("../../metrics");
const bycript = require('bcryptjs');
const uuidv1 = require('uuid/v1');
const saltRounds = 2;

require('dotenv').config();
const pass=process.env.password;
const host=process.env.host;

const pg=require("pg");

const conf={

    user: 'dbuser',
    host: host,
    password: "foobarbaz",
    database: 'csye6225',
    port: '5432'};

pool = new pg.Pool(conf);
//cloud watch start

const logger = require('../../config/winston');

const SDC = require('statsd-client'), sdc = new SDC({host: 'localhost', port: 8125});

 // Token based Authentication - GET
router.get("/self",(req,res)=>{
    var d = new Date();
    var n = d.getMilliseconds();


    logger.info("USER_GET LOG");
    sdc.increment('USER_GET counter');
    


console.log(req.headers.authorization)

if (req.headers.authorization && req.headers.authorization.search('Basic ') === 0) {
    // Get the username and password
    var header = new Buffer(req.headers.authorization.split(' ')[1], 'base64').toString();
    header = header.split(":");

    var username1 = header[0];
    var password1 = header[1];
    
    console.log(username1)
    console.log(password1)

    pool.query("SELECT  first_name, last_name , password,email_address,account_created, account_updated FROM Users where email_address = '"+username1+"'", (error, results) => {
        if(error){
            throw error;
        }
        else if(results.rowCount >0) {
            console.log("meetveera"+results.rows[0].password);
            var pa = results.rows[0].password;
            console.log("veerameet"+pa);
            bycript.compare(password1, pa, (error, result) => {

                // pool.query("SELECT email, firstname, lastname FROM users where email = '"+username1+"' and PASSWORD='"+password1+"'", (error, results) => {
                     if(result == true){
                         console.log("checksfe"+results.rows[0]);

                         logger.info("the User with username '"+username1+"' retrieved");

                             res.status(200).json({
                                 EMAIL: results.rows[0].email_address,
                                 FIRST_NAME: results.rows[0].first_name,
                                 LAST_NAME: results.rows[0].last_name,
                                 Created_Time: results.rows[0].account_created,
                                 Updated_Time:results.rows[0].account_updated


                             })
                 }
                 
                         
                         else{
                             console.log("checksfe"+results);
                             logger.error("Please enter valid username and password");
                             res.status(401).json({
                                message:"invalid username or password"
                             })
                         }
                 
                        
                        
                     });
        }
        else{
            res.status(401).json({
                                 
                message:"invalid username or password"
            })
        }
    });
    
    
  
};
var n1 = d.getMilliseconds();
var duration = (n1-n);
sdc.timing("Get User Time Duration",duration);
});
   

  
           

router.post("/",(req,res,next)=>{
    var d = new Date();
    var n = d.getMilliseconds();

    logger.info("USER_POST LOG");
    sdc.increment('USER_POST_counter');
    sdc.timing('some.timer');
    


  

    var date_ob = new Date();

    //
   
let date = ("0" + date_ob.getDate()).slice(-2);

// // current month
 let month = ("0" + (date_ob.getMonth() + 1)).slice(-2);

// // current year
 let year = date_ob.getFullYear();

// // current hours
 let hours = date_ob.getHours();

// // current minutes
 let minutes = date_ob.getMinutes();

// // current seconds
 let seconds = date_ob.getSeconds();



// prints date & time in YYYY-MM-DD HH:MM:SS format
const timestamp=(year + "-" + month + "-" + date + " " + hours + ":" + minutes + ":" + seconds);
console.log(timestamp); 

const u=uuidv1();
const users={
        uuid : u,
        email1: req.body.email,
        password1: req.body.password,
        firstname1: req.body.firstname,
        lastname1: req.body.lastname,
        created_time: timestamp

    };
    console.log(JSON.stringify(conf));
//Meet Start
    const emailregex = /^[-!#$%&'*+\/0-9=?A-Z^_a-z{|}~](\.?[-!#$%&'*+\/0-9=?A-Z^_a-z`{|}~])*@[a-zA-Z0-9](-*\.?[a-zA-Z0-9])*\.[a-zA-Z](-?[a-zA-Z0-9])+$/;
    const passregex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$%\^&\*])(?=.{8,})/;

    var validemail = emailregex.test(users.email1);
    var validpass = passregex.test(users.password1);
    if(!validemail){
        res.status(401).
            json({ messege:"please enter a valid email",});
    
    }
    else if(!validpass){
        res.status(401).
            json({ messege:"please enter a strong password",});
    }
    else if((users.email1=="") || (users.firstname1=="") || (users.firstname1=="") || (users.lastname1=="")){
        res.status(401).
            json({ messege:"please enter all the fields",});
    }
    else if(!users.email1==""){
        pool.query("SELECT * FROM Users WHERE email_address='"+users.email1+"'",(error,results) => {
            if(error){
                throw error
            }
            else{
             //   console.log("length"+results.length);
             //   console.log("count"+results.rows.count);
                if(results.rowCount>0){
                    res.status(401).
                    json({ messege:"User already exists",});
                }
                else{
                    sdc.timing('USER_response_time');
                    bycript.hash(users.password1,saltRounds,function(err,hash){
                        pool.query("INSERT INTO Users (id,first_name,last_name,password,email_address,account_created, account_updated) VALUES ('"+users.uuid+"','"+users.firstname1+"','"+users.lastname1+"','"+hash+"','"+users.email1+"','"+timestamp+"','"+timestamp+"')", (error, results) => {
                            if(error){
                                throw error
                            }
                            console.log(error, results);
                        res.status(200).json({
                        messege:"User created successfully",
                        email1: req.body.email,
                        UUID: users.uuid,
                        firstname1: req.body.firstname,
                        lastname1: req.body.lastname,
                        created_time: timestamp
                
                    
                });
                });
                });
                    }
                //console.log(results.rows[0]);
            }
        }); 
    }
//Meet End
//var d = new Date();
var n1 = d.getMilliseconds();
var duration = (n1-n);
sdc.timing("Post User Time Duration",duration);
});



router.put("/self",(req,res,next)=>{
    var d = new Date();
    var n = d.getMilliseconds();
    logger.info("USER_PUT LOG");
    sdc.increment('USER_PUT counter');
    console.log(req.headers.authorization)

if (req.headers.authorization && req.headers.authorization.search('Basic ') === 0) {
    // Get the username and password
    var header = new Buffer(req.headers.authorization.split(' ')[1], 'base64').toString();
    header = header.split(":");

    var usernameREQ = header[0];
    var passwordREQ = header[1];
    
    console.log(usernameREQ)
    console.log(passwordREQ)

    pool.query("SELECT  first_name, last_name , password FROM Users where email_address = '"+usernameREQ+"'", (error, results) => {
        if(error){
            throw error;
        }
        else if(results.rowCount >0) {
            console.log("meetveera"+results.rows[0].password);
            var pa = results.rows[0].password;
            console.log("veerameet"+pa);
            bycript.compare(passwordREQ, pa, (error, result) => {

                // pool.query("SELECT email, firstname, lastname FROM users where email = '"+username1+"' and PASSWORD='"+password1+"'", (error, results) => {
                     if(result == true){
                         console.log("VERIFIED")
                            var date_ob = new Date();
                            console.log(date_ob);
                            let date = ("0" + date_ob.getDate()).slice(-2);
                     
                            // // current month
                            let month = ("0" + (date_ob.getMonth() + 1)).slice(-2);
                     
                            // // current year
                            let year = date_ob.getFullYear();
                     
                            // // current hours
                            let hours = date_ob.getHours();
                     
                            // // current minutes
                            let minutes = date_ob.getMinutes();
                     
                            // // current seconds
                            let seconds = date_ob.getSeconds();
                     
                            // prints date & time in YYYY-MM-DD HH:MM:SS format
                            const timestamp1=(year + "-" + month + "-" + date + " " + hours + ":" + minutes + ":" + seconds);
                            console.log(timestamp1); 
                             const users={
                                          email1: usernameREQ,
                                          password1: req.body.password,
                                        firstname1: req.body.firstname,
                                         lastname1: req.body.lastname,
                                         updated_time: timestamp1
                     
                                        };

                                        
                            const passregex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$%\^&\*])(?=.{8,})/;
                     
                            var validpass = passregex.test(users.password1);
                            if(!validpass){
                                        res.status(401).
                                        json({ messege:"please enter a strong password",});
                                         }
                            else if((users.password1=="") || (users.firstname1=="") || (users.lastname1=="")){
                                        res.status(401).
                                        json({ messege:"please enter all the fields",});
                                         }
                            else{
                                bycript.hash(users.password1,saltRounds,function(err,hash){
                                    pool.query("UPDATE Users SET password='"+hash+"', first_name='"+users.firstname1+"',last_name='"+users.lastname1+"',account_updated='"+users.updated_time+"' where email_address='"+users.email1+"'", (error, results) => {
                                        if(error){
                                            throw error
                                        }
                                            console.log(error, results);
                                            
                                             res.status(200).json({
                                                     messege:"User Updated successfully",
                                                    EMAIL: users.email1,
                                                     FIRST_NAME: users.firstname1,
                                                     LAST_NAME: users.lastname1,
                                                     Updated_TIme: users.update_time
                                         
                                                 });
                                                });          
                                        
    
  
                                            });

                                }
                     }
                     else{
                        res.status(401).json({
                                             
                            message:"invalid username or password"
                        })
                    }
            });
        }
        else{
            res.status(401).
            json({ messege:"This user does not exists",});
             }
      
    });
}
var n1 = d.getMilliseconds();
var duration = (n1-n);
sdc.timing("Put User time duration",duration);
});
        

module.exports=router;

