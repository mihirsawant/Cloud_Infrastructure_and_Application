const express=require("express");
const jwt = require("jsonwebtoken");
const path=require("path");
const bodyparser=require("body-parser");
const pg=require("pg");
require('dotenv').config();
const app = express();
const pass=process.env.password;
const host=process.env.host;
const usersRoutes=require("./api/routes/users");
const recipeRoutes=require("./api/routes/recipe");

const conf={

      user: 'dbuser',
      host: host,
      database: 'csye6225',
      password: "foobarbaz",
      port: '5432'};

var pool;

console.log(JSON.stringify(conf));

module.exports = {
      getPool: function (){
      if (pool) return pool; // if it is already there, grab it here
      pool = new pg.Pool(conf);
      return pool;
}};

// pool = new pg.Pool(conf)
// pool.query("CREATE TABLE IF NOT EXISTS USERS(id varchar(50), first_name varchar(20), last_name varchar(20), password varchar(100), email_address varchar(100), account_created timestamp, account_updated timestamp)", (err, res) => {
// console.log(err, res);
// console.log(res.rows);
// console.log("Table Created");
// pool.query("CREATE TABLE IF NOT EXISTS RECIPE(id varchar(50), created_ts timestamp, updated_ts timestamp, author_id varchar(50), cook_time_in_min int, prep_time_in_min int, total_time_in_min int, title varchar(100), cusine varchar(100), servings int, ingredients varchar(1000), steps varchar(50), nutrition_information varchar(50))", (err, res) => {
//       console.log(err, res);
//       console.log(res.rows);
//       console.log("Table Created");
//       pool.query("CREATE TABLE IF NOT EXISTS NUTRITIONINFORMATION(id varchar(50), calories int, cholesterol_in_mg float, sodium_in_mg int, carbohydrates_in_grams float, protein_in_grams float)", (err, res) => {
//             console.log(err, res);
//             console.log(res.rows);
//             console.log("Table Created");
//             pool.query("CREATE TABLE IF NOT EXISTS IMAGE(id varchar(50), url varchar(200) ,loc varchar(400))", (err, res) => {
//                   console.log(err, res);
//                   console.log(res.rows);
//                   console.log("Table Created");
//                   pool.query("CREATE TABLE IF NOT EXISTS ORDEREDLIST(id varchar(50), position int, items varchar(100))", (err, res) => {
//                         console.log(err, res);
//                         console.log(res.rows);
//                         console.log("Table Created");
// pool.end();
// });});});});});

pool = new pg.Pool(conf)
pool.query("CREATE TABLE IF NOT EXISTS USERS(id varchar(50), first_name varchar(20), last_name varchar(20), password varchar(100), email_address varchar(100), account_created timestamp, account_updated timestamp)", (err, res) => {
console.log(err, res);
//console.log(res.rows);
console.log("Table Created");
pool.end();
});


pool = new pg.Pool(conf)
pool.query("CREATE TABLE IF NOT EXISTS RECIPE(id varchar(50), created_ts timestamp, updated_ts timestamp, author_id varchar(50), cook_time_in_min int, prep_time_in_min int, total_time_in_min int, title varchar(100), cusine varchar(100), servings int, ingredients varchar(1000), steps varchar(50), nutrition_information varchar(50))", (err, res) => {
console.log(err, res);
//console.log(res.rows);
console.log("Table Created");
pool.end();
});

pool = new pg.Pool(conf)
pool.query("CREATE TABLE IF NOT EXISTS NUTRITIONINFORMATION(id varchar(50), calories int, cholesterol_in_mg float, sodium_in_mg int, carbohydrates_in_grams float, protein_in_grams float)", (err, res) => {
console.log(err, res);
//console.log(res.rows);
console.log("Table Created");
pool.end();
});


pool = new pg.Pool(conf)
pool.query("CREATE TABLE IF NOT EXISTS IMAGE(id varchar(50), url varchar(200) ,loc varchar(400))", (err, res) => {
console.log(err, res);
//console.log(res.rows);
console.log("Table Created");
pool.end();
});

pool = new pg.Pool(conf)
pool.query("CREATE TABLE IF NOT EXISTS ORDEREDLIST(id varchar(50), position int, items varchar(100))", (err, res) => {
console.log(err, res);
//console.log(res.rows);
console.log("Table Created");
pool.end();
});



app.use(bodyparser.urlencoded({extended:false}));
app.use(bodyparser.json());
app.use("/v1/users",usersRoutes);
app.use("/v1/reciepe",recipeRoutes);

app.get("/",(req,res)=>{

      res.status(200).json({
          message: "WELCOME"
      });
  });
     


module.exports=app

