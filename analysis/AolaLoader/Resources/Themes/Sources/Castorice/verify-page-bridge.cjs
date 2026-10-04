// Execute the production page script with a simulated Flash endpoint.
const fs=require('fs'),path=require('path'),vm=require('vm'),assert=require('assert');
const source=fs.readFileSync(path.resolve(__dirname,'../../../../BrowserHost/AolaPageBridge.cs'),'utf8');
const template=source.split('return @"')[1].split('})(" + operationJson')[0].replace(/""/g,'"');
let calls=0,status='Loading';
const flash={aolaThemeApply(themeId,requestId){calls++;return JSON.stringify({status,themeId,requestId,message:''});}};
const context=vm.createContext({window:{},document:{getElementById:()=>flash,querySelectorAll:()=>[flash]}});
function run(themeId,requestId){return JSON.parse(vm.runInContext(template+'})("theme.apply",'+JSON.stringify({themeId,requestId})+')',context));}
assert.equal(run(9,1).value.status,'Loading');
const oldCallback=context.window.aolaThemeCompleted;
assert.equal(run(10,2).value.themeId,10);
assert.equal(oldCallback(1,JSON.stringify({requestId:1,themeId:9,status:'Applied'})),false);
assert.equal(context.window.aolaThemeCompleted(2,JSON.stringify({requestId:2,themeId:9,status:'Applied'})),false);
assert.equal(context.window.aolaThemeCompleted(2,JSON.stringify({requestId:2,themeId:10,status:'Applied'})),true);
assert.equal(run(10,2).value.status,'Applied');assert.equal(calls,2);
for(const id of [-1,11,10.5])assert.equal(run(id,3).ok,false);
assert.equal(calls,2);
status='WaitingBattleEnd';assert.equal(run(10,4).value.status,status);
status='NotReady';assert.equal(run(10,4).value.status,status);
status='Failed';assert.equal(run(10,4).value.status,status);
status='Applied';assert.equal(run(10,4).value.status,'Failed');
context.window={};assert.equal(run(10,5).value.status,'Applied');
assert.equal(run(0,6).value.themeId,0);
console.log('PASS: theme10; range boundaries; stale/wrong-theme callbacks; pending battle/visibility; failure retained; new page reapplies; official default request. Simulated endpoint only.');
