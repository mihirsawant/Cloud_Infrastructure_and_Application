const express=require("express");
const router=express.Router();
const app=require("../../app");

const bycript = require('bcryptjs');
const saltRounds = 2;
const uuidv1 = require('uuid/v1');
const pg=require("pg");

require('dotenv').config();
//const pass=process.env.password;
const host=process.env.host;
const conf={

    user: 'dbuser',
    host: host,
    password: "foobarbaz",
    database: 'csye6225',
    port: '5432'};



pool = new pg.Pool(conf);
// meet s3 start
//cloudwatch
const SDC = require('statsd-client'), sdc = new SDC({host: 'localhost', port: 8125});

const logger = require('../../config/winston');
//cloudwatch-end
const aws = require('aws-sdk');
const multer = require('multer');
const multerS3 = require('multer-s3');
//const config = require('../../config');

//hgfdsfgfdd
aws.config.update({

    secretAccessKey: process.env.secret,
    accessKeyId:process.env.access,
    region:'us-east-1'
});
//sns
var sns = new aws.SNS({});
//sns end
//get all reciepies
router.post("/myrecipies",(req,res,next)=>{
    if (req.headers.authorization && req.headers.authorization.search('Basic ') === 0){
        var header = new Buffer(req.headers.authorization.split(' ')[1], 'base64').toString();
        header = header.split(":");

        var username1 = header[0];
        var password1 = header[1];
    
        console.log(username1);
        console.log(password1);
        pool.query("SELECT  id,first_name, last_name , password,email_address,account_created, account_updated FROM Users where email_address = '"+username1+"'", (error, results) => {
            if(error){
                throw error;
            }
            else if(results.rowCount >0) {
               
                var pa = results.rows[0].password;
                var id = results.rows[0].id;
                
                bycript.compare(password1, pa, (error, result) => {
    
                    
                        if(result == true){
                            pool.query("SELECT id, author_id FROM RECIPE WHERE author_id='"+id+"'",(error,results4)=>{
                                if(error){
                                    throw error;
                                }
                                else{
                                    var a= results4.rowCount;
                                    logger.info("gfd"+a);
                                    console.log("recipiesvgsfvsvs"+a);
                                    let topicParams = {Name: 'EmailTopic'};
                                    
                                    sns.createTopic(topicParams, (err, data) => {
                                    global.recipeLink = "";
                                    var recipeLinks=[];
                                    var abcd= process.env.domain;
                                    logger.info(abcd+"gfdsf");
                                    if (err) console.log(err);
                                    
                                    else {
                                        for (var i = 0; i <a; i++) {
                                            //recipeLinks[i] = 'ec2-23-20-238-63.compute-1.amazonaws.com:3000/v1/reciepe/'+results4.rows[i].id;
                                            recipeLinks[i] = 'https://'+process.env.domain+'/v1/reciepe/'+results4.rows[i].id;
                                           // let resetLink = 'http://'+process.env.DOMAIN_NAME+'?email=' + email + '&token=' + uuidv4();
                                            logger.info(recipeLinks[i]+"alalalalalal");
                                        }
                                        var abc = JSON.stringify(recipeLinks);
                                        logger.info(abc+"hgfdfd");
                                        logger.info("gfd");
                                        let sourceEmail = 'csye6225@'+process.env.domain;
                                       // var abc = this.recipeLink0;
                                       // var cdf = this.recipeLink1;
                                        //let recipeLink = 'ec2-23-20-238-63.compute-1.amazonaws.com:3000/v1/reciepe/'+results4.rows[0].id;
                                        let payload = {
                                        default: 'Hello World',
                                        data: {
                                            Email: results.rows[0].email_address,
                                            link: recipeLinks,
                                            sourceE : sourceEmail,
                                        }
                                        };
                                        payload.data = JSON.stringify(payload.data);
                                        payload = JSON.stringify(payload);
                                        let params = {Message: payload, TopicArn: data.TopicArn}
                                        sns.publish(params, (err, data) => {
                                        if (err) console.log(err)
                                        else {
                                            console.log('published')
                                    
                                            res.status(201).json({
                                                "message": "recipe link sent on email Successfully!",
                                                "data" : payload.data
                                            });
                                        }
                                        })
                                    }
                                    })
                                }
                            });
                            
                                
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
    }
})



router.post("/:recid/image",(req,res,next)=>{

    var d = new Date();
    var n = d.getMilliseconds();
    logger.info("RECIPE_IMG_POST LOG");
    sdc.increment('RECIPE_IMG_POST counter');
    const RecId=req.params.recid;
   
const s3 = new aws.S3();
var fileloc ="";
const fileFilter = (req,file,cb)=>{
    if(file.mimetype ==='image/jpg' || file.mimetype === 'image/jpeg' || file.mimetype === 'image/png'){
        cb(null,true)
    }
    else{
        cb(new Error('invalid mime type, only jpeg and png are accepted'),false);
    }
}


const upload = multer({
    fileFilter,
  storage: multerS3({
    s3: s3,
    bucket:process.env.bucket,
    metadata: function (req, file, cb) {
        console.log(file);
       fileloc=file;
      cb(null, {fieldName: file.fieldname});
    },
    key: function (req, file, cb) {
      cb(null, RecId)
    }
  })
})
const singleupload = upload.single('image');

    console.log("REC ID:"+RecId);
    if (req.headers.authorization && req.headers.authorization.search('Basic ') === 0) {
        // Get the username and password
        var header = new Buffer(req.headers.authorization.split(' ')[1], 'base64').toString();
        header = header.split(":");
    
        var usernameREQ = header[0];
        var passwordREQ = header[1];

    pool.query("SELECT  * from recipe where id = '"+RecId+"'", (error, results) => {
        if(error){
            throw error;
        }
        else if(results.rowCount>0){
            authorID=results.rows[0].author_id;
            console.log("AUTHOR ID :"+authorID);
            pool.query("SELECT  * FROM Users where email_address = '"+usernameREQ+"'", (error, results2) => {
                if(error){
                    throw error;
                }
                else if(results2.rowCount >0) {
                    console.log("priyal"+results2.rows[0].password);
                    var pa = results2.rows[0].password;
                    console.log("veerameet"+pa);
                    bycript.compare(passwordREQ, pa, (error, result) => {
                        if(error){
                            throw error;
                        }
                        if(result == true){
                            if( results2.rows[0].id==authorID){

                                const u2 = uuidv1();
                                singleupload(req,res,function(err){
                                    if(err){
                                        return res.status(400).send({errors:[{title:'File upload error',detail:err.message}]});
                                    }
                                    if(req.file.location == ''){
                                        res.status(400).json({message:"Please select the image and send"});
                                    }
                                    // else if(filetype == "false"){
                                    //     logger.error("image for reciepe should be jpeg");

                                    //     res.status(400).json({message: "Please select jpeg file only"});
                                    //  }
                                    else{
                                    pool.query("INSERT INTO image (id,url, loc) VALUES ('"+RecId+"','"+req.file.location+"','"+fileloc+"')", (error, results) => {
                                        if(error){
                                            throw error;
                                        }
                                        else{
                                            logger.info("Image with id '"+RecId+"'added successfully");
                                            return res.status(200).json({'id' : RecId,
                                                                        'url':req.file.location,
                                                                    metadata:fileloc});

                                        }
                                    });

                                }
                                });
                                    }
                                
                            else {
                                console.log("You Cannot update this recipie");
                                res.status(401).
                                        json({ messege:"You Cannot update this recipie"});
                            }
                            
                        }
                        if(result == false){
                            console.log("Authentication Failed(password)");
                            res.status(401).
                            json({ messege:"Authentication Failed(password)"});
                        }
                    })
                    
                    }
                    else if(results2.rowCount <1) {
                        console.log("Authentication failed(email)");
                        res.status(401).
                        json({ messege:"Authentication failed(email)"});
                    }
    });
    }
    else if(results.rowCount==0){
        console.log("invalid recipie id");
        logger.error("No such reciepe found")
        res.status(404).
         json({ messege:"recipie Not Found"});
    }
});
    }

    var n1 = d.getMilliseconds();
    var duration = (n1-n);
    sdc.timing("Post Image to S3",duration);
})

router.get("/:recid/image/:imageid",(req,res)=>{

    var d = new Date();
    var n = d.getMilliseconds();
    logger.info("RECIPE_IMG_GET LOG");
    sdc.increment('RECIPE_IMG_GET counter');


    const RecId=req.params.recid;
    const ImageId = req.params.imageid;
    console.log(RecId);
    console.log(ImageId);
    pool.query("SELECT  * from recipe where id = '"+RecId+"'", (error, results) => {
        if(error){
            throw error;
        }
        
        else if(results.rowCount >0) {
            pool.query("SELECT id, url, loc  FROM image where id='"+ImageId+"'", (error, result2)=>{
                if(error){
                   throw error
                }
                else{
                    if(result2.rowCount >0){

                        logger.info('reciepe receive successfully')
                        res.status(200).json({
                            
                        
                            id :result2.rows[0].id,
                            url : result2.rows[0].url,
                            metadata: result2.rows[0].loc
                           });
                    }
                    else{
                        logger.error('Image not found error')
                        res.status(404).json({
                            
                            messege: 'Image Not found, Please enter a correct image ID',
                            
                
                            });
                    }
                    
                }
                
               
          
    });
    

    }
    else{
        logger.error('Reciepe not found error')
        res.status(404).json({
            Messege: "recipie not found"
        });

    }
});
var n1 = d.getMilliseconds();
var duration = (n1-n);
sdc.timing("Get Image from S3 Time",duration);
});


// meet s3 end


// priyal start - delete image S3 bucket and database
router.delete("/:recid/image/:imageid",(req,res)=>{

    var d = new Date();
    var n = d.getMilliseconds();
    logger.info("RECIPE_IMG_DEL LOG");
    sdc.increment('RECIPE_IMG_DEL counter');
    
    const RecId=req.params.recid;
    const ImageId = req.params.imageid;
    

    console.log("REC ID:"+RecId);
    console.log("IMAGE ID :"+ImageId); 
    
    
    if (req.headers.authorization && req.headers.authorization.search('Basic ') === 0) {
        // Get the username and password
        var header = new Buffer(req.headers.authorization.split(' ')[1], 'base64').toString();
        header = header.split(":");
    
        var usernameREQ = header[0];
        var passwordREQ = header[1];

    pool.query("SELECT  * from recipe where id = '"+RecId+"'", (error, results) => {
        if(error){
            throw error;
        }
        else if(results.rowCount>0){
            authorID=results.rows[0].author_id;
            console.log("AUTHOR ID :"+authorID);
            pool.query("SELECT  * FROM Users where email_address = '"+usernameREQ+"'", (error, results2) => {
                if(error){
                    throw error;
                }
                else if(results2.rowCount >0) {
                    console.log("priyal"+results2.rows[0].password);
                    var pa = results2.rows[0].password;
                    console.log("veerameet"+pa);
                    bycript.compare(passwordREQ, pa, (error, result) => {
                        if(error){
                            throw error;
                        }
                        if(result == true){
                            if( results2.rows[0].id==authorID){

                                const s3 = new aws.S3();
                                var params = { Bucket: process.env.bucket, Key: RecId }
                                s3.deleteObject(params, function (err, data) {
                                    if (err) {
                                        return res.send({ "error": err });
                                    }
                                  //  res.send({ data });
                                });
                            
                                pool.query("DELETE FROM image where id = '"+ImageId+"'", (error, results2) => {
                                    if(error){
                                        throw error;
                                    }
                                    else{
                                        logger.info("reciepe with id '"+ImageId+"' and image deleted successfully");
                                        res.status(200).
                                        json({ messege:"image DELETED SUCCESSFULLY from database and Amazon S3 bucket"});

                                    }
                                });

                                
                                    }
                                
                            else {
                                console.log("You Cannot delete this image");
                                res.status(401).
                                        json({ messege:"You Cannot delete this image"});
                            }
                            
                        }
                        if(result == false){
                            console.log("Authentication Failed(password)");
                            res.status(401).
                            json({ messege:"Authentication Failed(password)"});
                        }
                    })
                    
                    }
                    else if(results2.rowCount <1) {
                        console.log("Authentication failed(email)");
                        res.status(401).
                        json({ messege:"Authentication failed(email)"});
                    }
    });
    }
    else if(results.rowCount==0){
        console.log("invalid recipie id");
        res.status(404).
         json({ messege:"recipie Not Found"});
    }
});
    }

    var n1 = d.getMilliseconds();
    var duration = (n1-n);
    sdc.timing("Delete User From S3 Time",duration);
})


router.post("/",(req,res,next)=>{

    var d = new Date();
    var n = d.getMilliseconds();
    logger.info("RECIPE_POST LOG");
    sdc.increment('RECIPE_POST counter');


    var date_ob=new Date();
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
//const u1 = uuidd();
const u1 = uuidv1();
const recipie={
        

        cook_time_in_min: req.body.cook_time_in_min,
        prep_time_in_min: req.body.prep_time_in_min,
        title: req.body.title,
        cusine: req.body.cusine,
        serving : req.body.servings,
        ingredients: req.body.ingredients,
        steps : req.body.steps,
        nutrition_information : req.body.nutrition_information

    };
    var stringObj = JSON.stringify(recipie.ingredients);
    if (req.headers.authorization && req.headers.authorization.search('Basic ') === 0) {
        // Get the username and password
        var header = new Buffer(req.headers.authorization.split(' ')[1], 'base64').toString();
        header = header.split(":");

    
        var username1 = header[0];
        var password1 = header[1];
        

        var total = Number(recipie.prep_time_in_min) + Number(recipie.cook_time_in_min);
        pool.query("SELECT  id, first_name, last_name , password FROM Users where email_address = '"+username1+"'", (error, results) => {
            if(error){
                throw error;
            }
            else if(results.rowCount >0) {
               
                var pa = results.rows[0].password;
                var uuid = results.rows[0].id;

                bycript.compare(password1, pa, (error, result) => {

                    // pool.query("SELECT email, firstname, lastname FROM recipie where email = '"+username1+"' and PASSWORD='"+password1+"'", (error, results) => {
                         if(result == true){
                                if((Number(recipie.cook_time_in_min)%5!= 0) || (Number(recipie.prep_time_in_min) %5 !=0)){
                                    res.status(400).json({
                                        messege:"please enter cook time  and prep time in the multiple of 5",
                                    });
                                }
                                else if(Number(recipie.serving) > 5){
                                    logger.error("Servings cannot be more than 5");

                                    res.status(400).json({
                                        
                                        messege:"Maximum number of servings can be 5",
                                    });
                                }
                                else{
                                //insert code of receipe into d
                                pool.query("INSERT INTO recipe (id,created_ts,updated_ts,author_id,cook_time_in_min,prep_time_in_min,total_time_in_min,title,cusine,servings,ingredients,steps,nutrition_information) VALUES ('"+u1+"','"+timestamp+"','"+timestamp+"','"+uuid+"','"+recipie.cook_time_in_min+"','"+recipie.prep_time_in_min+"','"+total+"','"+recipie.title+"','"+recipie.cusine+"','"+recipie.serving+"','"+stringObj+"','"+u1+"','"+u1+"')", (error, results) => {
                                    console.log(u1+"    U1");
                                    console.log(uuid+ "UUID");


                                    console.log(recipie.nutrition_information.carbohydrates_in_grams+"    cook");

                                    console.log(total)
                                    if(error){
                                        throw error
                                    }
                                });
                           

                                pool.query("INSERT INTO NUTRITIONINFORMATION(id,calories,cholesterol_in_mg, sodium_in_mg, carbohydrates_in_grams , protein_in_grams) VALUES ('"+u1+"','"+recipie.nutrition_information.calories+"','"+recipie.nutrition_information.cholesterol_in_mg+"','"+recipie.nutrition_information.sodium_in_mg+"','"+recipie.nutrition_information.carbohydrates_in_grams+"','"+recipie.nutrition_information.protein_in_grams+"')"),(error,results)=>{

                                    if(error){
                                        throw error
                                    }
                                }
                                var values = [];
                                var values1 = [];
                                for (var i=0;i<recipie.steps.length;i++){

                               
                                    values.push([recipie.steps[i].position]);
                                    values1.push([recipie.steps[i].items]);
                                   
                                   

                                    pool.query("INSERT INTO orderedlist (id,position,items) VALUES ('"+u1+"','"+values[i]+"','"+values1[i]+"')",(error,results1)=>{
                                        if(error){
                                            throw error
                                        }
                                       
                                    });

                                }
                                logger.info("Reciepe with id '"+u1+"' created successfully");
                                res.status(200).json({
                                    id : u1,
                                    created_ts : timestamp,
                                    updates_ts : timestamp,
                                    authur_id : uuid,
                                    cook_time_in_min : recipie.cook_time_in_min,
                                    prep_time_in_min : recipie.prep_time_in_min,
                                    Total_time_in_min: total,
                                    title : recipie.title,
                                    cusine : recipie.cusine,
                                    servings : recipie.servings,
                                    ingredients: recipie.ingredients,
                                    steps : recipie.steps,
                                    nutrition_information : recipie.nutrition_information,
                                     messege:"Reciepe created successfully",

                                });    
                        }
                        }
                        else{
                            res.status(401).json({
                                message : "please enter a valid password"
                            })
                        }
                    });
                }
                else{
                    res.status(401).json({
                        message: "Please enter a valid email id or create one"
                    })
                }
            });
        };
        var n1 = d.getMilliseconds();
var duration = (n1-n);
sdc.timing("Post Recipe Time",duration);
    });

        
 /////////////// MIHIR_GET///////////////////////////////////////////////////////////////////////////////////////////////////////       
router.get("/:recid",(req,res)=>{

    var d = new Date();
    var n = d.getMilliseconds();
    logger.info("RECIPE_GET LOG");
    sdc.increment('RECIPE_GET counter');


    const RecId=req.params.recid;
    console.log(RecId);
    pool.query("SELECT  * from recipe where id = '"+RecId+"'", (error, results) => {
        if(error){
            throw error;
        }
        
        else if(results.rowCount >0) {
            pool.query("SELECT calories, cholesterol_in_mg,sodium_in_mg, carbohydrates_in_grams, protein_in_grams  FROM nutritioninformation where id='"+RecId+"'", (error, result2)=>{
                if(error){
                    throw error;
                }
                else{
                    pool.query("select position,items from orderedlist where id='"+RecId+"'",(error, result3)=>{
                        if(error){
                            throw error;
                        }
                        else{
                            pool.query("select id, url from image where id='"+RecId+"'",(error, result4)=>{
                                if(error){
                                    throw error;
                                }
                        

                                else{
                                    var abc = JSON.parse(results.rows[0].ingredients);
                                    res.status(200).json({
                            
                                    //messege: RecId,
                                    image: result4.rows,
                                    id: results.rows[0].id,
                                    created_ts: results.rows[0].created_ts,
                                    updated_ts: results.rows[0].updated_ts,
                                    author_id: results.rows[0].author_id,
                                    cook_time_in_min:results.rows[0].cook_time_in_min,
                                    prep_time_in_min: results.rows[0].prep_time_in_min,
                                    total_time_in_min: results.rows[0].total_time_in_min,
                                    title: results.rows[0].title,
                                    cusine: results.rows[0].cusine,
                                    servings: results.rows[0].servings,
                                    ingredients: abc,
                                    steps: result3.rows,
                                    nutrition_information: result2.rows
                    
                                    });
                            
                                }   
                        
                            });
                        }
                    });
                }     
            });
        }
    else{
        res.status(404).json({
            Messege: "recipie not found"
        });

    }
});
var n1 = d.getMilliseconds();
var duration = (n1-n);
sdc.timing("Get Recipe time",duration);
});
//////////////////////////////////PRIYAL PUT//////////////////////////////////////////


router.put("/:recid",(req,res)=>{

    var d = new Date();
    var n = d.getMilliseconds();
    logger.info("RECIPE_PUT LOG");
    sdc.increment('RECIPE_PUT counter');


    var date_ob=new Date();
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
const recipie={
                               
    cook_time_in_min: req.body.cook_time_in_min,
    prep_time_in_min: req.body.prep_time_in_min,
    title: req.body.title,
    cusine: req.body.cusine,
    serving : req.body.servings,
    ingredients: req.body.ingredients,
    steps : req.body.steps,
    nutrition_information : req.body.nutrition_information


 };
 var stringObj = JSON.stringify(recipie.ingredients);
    const RecId=req.params.recid;
    console.log("REC ID:"+RecId);
    if (req.headers.authorization && req.headers.authorization.search('Basic ') === 0) {
        // Get the username and password
        var header = new Buffer(req.headers.authorization.split(' ')[1], 'base64').toString();
        header = header.split(":");
    
        var usernameREQ = header[0];
        var passwordREQ = header[1];

    pool.query("SELECT  * from recipe where id = '"+RecId+"'", (error, results) => {
        if(error){
            throw error;
        }
        else if(results.rowCount>0){
            authorID=results.rows[0].author_id;
            console.log("AUTHOR ID :"+authorID);
            pool.query("SELECT  * FROM Users where email_address = '"+usernameREQ+"'", (error, results2) => {
                if(error){
                    throw error;
                }
                else if(results2.rowCount >0) {
                    console.log("priyal"+results2.rows[0].password);
                    var pa = results2.rows[0].password;
                    console.log("veerameet"+pa);
                    bycript.compare(passwordREQ, pa, (error, result) => {
                        if(error){
                            throw error;
                        }
                        if(result == true){
                            if( results2.rows[0].id==authorID){
                                
                                console.log("U CAN UPDATE");
                                if((Number(recipie.cook_time_in_min)%5!= 0) || (Number(recipie.prep_time_in_min) %5 !=0)){
                                    res.status(400).json({
                                        messege:"please enter cook time  and prep time in the multiple of 5",
                                    });
                                }
                                else if(Number(recipie.serving) > 5){
                                    res.status(400).json({
                                        messege:"Maximum number of servings can be 5",
                                    });
                                }
                                else{
                                    var total = Number(recipie.prep_time_in_min) + Number(recipie.cook_time_in_min);
                                    console.log(total);
                                    pool.query("UPDATE recipe SET  updated_ts ='"+timestamp+"', cook_time_in_min='"+recipie.cook_time_in_min+"', prep_time_in_min ='"+ recipie.prep_time_in_min+"', total_time_in_min ='"+total+"', title ='"+ recipie.title+"', cusine='"+recipie.cusine+"', servings='"+recipie.serving+"', ingredients='"+stringObj+"'where id ='"+RecId+"'",  (error, results3) => {
                                        if(error){
                                            throw error;
                                        }
                                    });
                                    pool.query("DELETE FROM nutritioninformation where id = '"+RecId+"'", (error, results8) => {
                                        if(error){
                                            throw error;
                                        }
    
                                    });
                                    pool.query("INSERT INTO NUTRITIONINFORMATION(id,calories,cholesterol_in_mg, sodium_in_mg, carbohydrates_in_grams , protein_in_grams) VALUES ('"+RecId+"','"+recipie.nutrition_information.calories+"','"+recipie.nutrition_information.cholesterol_in_mg+"','"+recipie.nutrition_information.sodium_in_mg+"','"+recipie.nutrition_information.carbohydrates_in_grams+"','"+recipie.nutrition_information.protein_in_grams+"')"),(error,results)=>{
                                        if(error){
                                            throw error
                                        }
                                    }
                                        pool.query("DELETE FROM orderedlist where id = '"+RecId+"'", (error, results8) => {
                                            if(error){
                                                throw error;
                                            }
        
                                        });
                                        var values = [];
                                        var values1 = [];
                                        for (var i=0;i<recipie.steps.length;i++){
                                        
                                            values.push([recipie.steps[i].position]);
                                            values1.push([recipie.steps[i].items]);
                                            
                                            
                                            pool.query("INSERT INTO orderedlist (id,position,items) VALUES ('"+RecId+"','"+values[i]+"','"+values1[i]+"')",(error,results1)=>{
                                                if(error){
                                                    throw error
                                                }
                                               
                                            });
                                        }
                                            res.status(200).json({
                                                id : RecId,
            
                                                updates_ts : timestamp,
                                                authur_id : authorID,
                                                cook_time_in_min : recipie.cook_time_in_min,
                                                prep_time_in_min : recipie.prep_time_in_min,
                                                Total_time_in_min: total,
                                                title : recipie.title,
                                                cusine : recipie.cusine,
                                                servings : recipie.servings,
                                                ingredients: recipie.ingredients,
                                                steps : recipie.steps,
                                                nutrition_information : recipie.nutrition_information,
                                                 messege:"Reciepe updated successfully",
                                            
                                            });    
                                
                                    
                                }
                      
                                    }
                                
                            else {
                                console.log("You Cannot update this recipie");
                                res.status(401).
                                        json({ messege:"You Cannot update this recipie"});
                            }
                            
                        }
                        if(result == false){
                            console.log("Authentication Failed(password)");
                            res.status(401).
                            json({ messege:"Authentication Failed(password)"});
                        }
                    })
                    
                    }
                    else if(results2.rowCount <1) {
                        console.log("Authentication failed(email)");
                        res.status(401).
                        json({ messege:"Authentication failed(email)"});
                    }

    });
    }
    else if(results.rowCount==0){
        console.log("invalid recipie id");
        res.status(404).
         json({ messege:"recipie Not Found"});
    }
});
    }
    var n1 = d.getMilliseconds();
var duration = (n1-n);
sdc.timing("Put Recipe Time",duration);
})



///////////////////////////////////////////////MIHIR_DEL///////////////////////////////////////////////////////////////////
router.delete("/:recid",(req,res)=>{

    var d = new Date();
    var n = d.getMilliseconds();
    logger.info("RECIPE_DEL LOG");
    sdc.increment('RECIPE_DEL counter');


    const RecId=req.params.recid;
    console.log("REC ID:"+RecId);
    if (req.headers.authorization && req.headers.authorization.search('Basic ') === 0) {
        // Get the username and password
        var header = new Buffer(req.headers.authorization.split(' ')[1], 'base64').toString();
        header = header.split(":");
    
        var usernameREQ = header[0];
        var passwordREQ = header[1];
    pool.query("SELECT  * from recipe where id = '"+RecId+"'", (error, results) => {
        if(error){
            throw error;
        }
        else if(results.rowCount>0){
            authorID=results.rows[0].author_id;
            console.log("AUTHOR ID :"+authorID);
            pool.query("SELECT  * FROM Users where email_address = '"+usernameREQ+"'", (error, results2) => {
                if(error){
                    throw error;
                }
                else if(results2.rowCount >0) {
                    console.log("meetveera"+results2.rows[0].password);
                    var pa = results2.rows[0].password;
                    console.log("veerameet"+pa);
                    bycript.compare(passwordREQ, pa, (error, result) => {
                        if(error){
                            throw error;
                        }
                        if(result == true){
                            if( results2.rows[0].id==authorID){
                                console.log("U CAN DEL");

                                pool.query("DELETE FROM recipe where id = '"+RecId+"'", (error, results2) => {
                                    if(error){
                                        throw error;
                                    }

                                });
                                pool.query("DELETE FROM nutritioninformation where id = '"+RecId+"'", (error, results2) => {
                                    if(error){
                                        throw error;
                                    }

                                });
                                pool.query("DELETE FROM orderedlist where id = '"+RecId+"'", (error, results2) => {
                                    if(error){
                                        throw error;
                                    }

                                });


                                res.status(200).
                                        json({ messege:"recipie DELETED SUCCESSFULLY"})
                            }
                            else{
                                console.log("You Cannot delete this recipie")
                                res.status(401).
                                        json({ messege:"You Cannot delete this recipie"});
                                         
                            }
                        }
                        if(result == false){
                            console.log("Authentication Failed(password)");
                            res.status(401).
                            json({ messege:"Authentication Failed(password)"});
                        }
                    })
                    
                    }
                    else if(results2.rowCount <1) {
                        console.log("Authentication failed(email)");
                        res.status(401).
                        json({ messege:"Authentication failed(email)"});
                    }
    });
    }
    else if(results.rowCount==0){
        console.log("invalid recipie id");
        res.status(404).
         json({ messege:"recipie Not Found"});
    }
});
    }
    var n1 = d.getMilliseconds();
var duration = (n1-n);
sdc.timing("Delete Recipe Time",duration);
})




module.exports=router;
//module.exports=upload;
