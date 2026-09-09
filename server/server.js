'use strict';
const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { URL } = require('url');

const PORT = Number(process.env.PORT || 8080);
const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, 'data');
const DATA_FILE = path.join(DATA_DIR, 'state.json');
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || '';
const ADMIN_SESSION_TTL = 24 * 60 * 60 * 1000;
const PLAYER_SESSION_TTL = 30 * 24 * 60 * 60 * 1000;
const sessions = new Map();
const rate = new Map();
const MAX_BODY = 1024 * 1024;

const DEFAULT_SETTINGS = {
  maintenance_mode:false, global_announcement:'', global_reward_multiplier:1,
  play_cost:0, daily_bonus_amount:25, daily_mission_reward:80, weekly_mission_reward:350,
  return_bonus_base:100, return_bonus_per_day:25, return_bonus_max_days:30,
  rating_success:3, rating_level_up:1, starting_rating:0,
  notification_enabled:true, notification_hours:{rewards:12,streak:20,chests:18},
  default_language:'ru', default_quality:2, default_fps:60
};
const DEFAULT_CATALOG = {
  toys: [
    ['bear','Мишка','ОБЫЧНАЯ'],['bunny','Зайчик','ОБЫЧНАЯ'],['panda','Панда','НЕОБЫЧНАЯ'],['duck','Уточка','ОБЫЧНАЯ'],
    ['dino','Динозавр','НЕОБЫЧНАЯ'],['cat','Котик','ОБЫЧНАЯ'],['fox','Лисёнок','РЕДКАЯ'],['frog','Лягушонок','РЕДКАЯ'],
    ['koala','Коала','РЕДКАЯ'],['tiger','Тигр','ЭПИЧЕСКАЯ'],['shark','Акула','ЭПИЧЕСКАЯ'],['penguin','Пингвин','НЕОБЫЧНАЯ'],
    ['dragon','Дракон','ЛЕГЕНДАРНАЯ'],['unicorn','Единорог','ЛЕГЕНДАРНАЯ'],['robot','Робот','ЭПИЧЕСКАЯ'],['space_cat','Космокот','МИФИЧЕСКАЯ'],
    ['space_shark','Космоакула','МИФИЧЕСКАЯ'],['star_panda','Звёздная панда','ЛЕГЕНДАРНАЯ']
  ].map(([id,name,rarity])=>({id,name,rarity,enabled:true,description:'Игрушка для коллекции',collection:'Базовая'})),
  collections: [
    {id:'basic',name:'Базовая коллекция',description:'Основные игрушки',difficulty:'Обычная',toy_ids:['bear','bunny','panda','duck','dino','cat'],reward:{type:'coins',amount:150},enabled:true},
    {id:'rare',name:'Охотники за редкими',description:'Редкие и эпические игрушки',difficulty:'Сложная',toy_ids:['fox','frog','koala','tiger','shark','robot'],reward:{type:'coins',amount:500},enabled:true},
    {id:'legendary',name:'Легенды автомата',description:'Самые редкие призы',difficulty:'Легендарная',toy_ids:['dragon','unicorn','space_cat','space_shark','star_panda'],reward:{type:'coins',amount:1500},enabled:true}
  ],
  shop: [
    {id:'claw_1',category:'claws',name:'СИЛА КЛЕШНИ I',description:'Улучшает шанс удержания',price:0,currency:'coins',level:1,effect:{capture_bonus:0.03},enabled:true},
    {id:'time_1',category:'upgrades',name:'ВРЕМЯ ИГРЫ I',description:'Больше времени на наведение',price:500,currency:'coins',level:1,effect:{game_time:5},enabled:true},
    {id:'luck_1',category:'upgrades',name:'ШАНС ЗАХВАТА I',description:'Повышает базовый шанс',price:700,currency:'coins',level:1,effect:{capture_bonus:0.05},enabled:true},
    {id:'claw_skin_gold',category:'claw_skins',name:'ЗОЛОТАЯ КЛЕШНЯ',description:'Визуальный скин',price:1200,currency:'coins',level:1,effect:{skin:'gold'},enabled:true},
    {id:'toy_skin_pastel',category:'toy_skins',name:'ПАСТЕЛЬНЫЕ ИГРУШКИ',description:'Меняет внешний вид игрушек',price:900,currency:'coins',level:1,effect:{skin:'pastel'},enabled:true}
  ],
  achievements: [
    {id:'first_win',name:'ПЕРВАЯ ИГРУШКА',description:'Получите первую игрушку',kind:'prizes',value:1,reward:{type:'coins',amount:50},enabled:true},
    {id:'wins_10',name:'ОХОТНИК',description:'Получите 10 игрушек',kind:'prizes',value:10,reward:{type:'coins',amount:200},enabled:true},
    {id:'wins_50',name:'МАСТЕР КЛЕШНИ',description:'Получите 50 игрушек',kind:'prizes',value:50,reward:{type:'coins',amount:700},enabled:true},
    {id:'chests_10',name:'ОТКРЫВАТЕЛЬ',description:'Откройте 10 сундуков',kind:'chests_opened',value:10,reward:{type:'keys',amount:2},enabled:true},
    {id:'referrals_1',name:'ДРУГ ПРИВЁЛ ДРУГА',description:'Пригласите 1 друга',kind:'referrals',value:1,reward:{type:'coins',amount:100},enabled:true}
  ]
};

function emptyState(){return {
  schema_version:2, settings:{...DEFAULT_SETTINGS}, promocodes:[], news:[], events:[], holidays:[], season:{id:'season_1',name:'Сезон 1',description:'Первый сезон',start_at:'',end_at:'',enabled:true,max_level:30,levels:[]}, chests:[], missions:{daily:[],weekly:[]}, catalog:JSON.parse(JSON.stringify(DEFAULT_CATALOG)), notifications:[], notification_history:[], system_marks:{}, players:{}, actions:{}, transactions:[], audit:[], admins:[]
};}
function loadState(){try{return JSON.parse(fs.readFileSync(DATA_FILE,'utf8'));}catch{return emptyState();}}
let state=loadState();
function migrate(){
  const e=emptyState();
  for(const k of Object.keys(e)) if(state[k]===undefined) state[k]=e[k];
  state.settings={...DEFAULT_SETTINGS,...(state.settings||{}),notification_hours:{...DEFAULT_SETTINGS.notification_hours,...((state.settings||{}).notification_hours||{})}};
  state.players=state.players||{}; state.audit=Array.isArray(state.audit)?state.audit:[]; state.notifications=Array.isArray(state.notifications)?state.notifications:[];
  state.notification_history=Array.isArray(state.notification_history)?state.notification_history:[]; state.actions=state.actions&&typeof state.actions==='object'?state.actions:{}; state.transactions=Array.isArray(state.transactions)?state.transactions:[];
  state.catalog={...e.catalog,...(state.catalog||{})};
  state.catalog.toys=Array.isArray(state.catalog.toys)?state.catalog.toys:e.catalog.toys;
  state.catalog.collections=Array.isArray(state.catalog.collections)?state.catalog.collections:e.catalog.collections;
  state.catalog.shop=Array.isArray(state.catalog.shop)?state.catalog.shop:e.catalog.shop;
  state.catalog.achievements=Array.isArray(state.catalog.achievements)?state.catalog.achievements:e.catalog.achievements;
  state.promocodes=Array.isArray(state.promocodes)?state.promocodes:[]; state.news=Array.isArray(state.news)?state.news:[]; state.events=Array.isArray(state.events)?state.events:[]; state.holidays=Array.isArray(state.holidays)?state.holidays:[]; state.chests=Array.isArray(state.chests)?state.chests:[];
  for(const p of Object.values(state.players)) normalizePlayer(p);
  state.schema_version=2; state.system_marks=state.system_marks&&typeof state.system_marks==='object'?state.system_marks:{};
  saveState();
}
function saveState(){fs.mkdirSync(DATA_DIR,{recursive:true});const tmp=DATA_FILE+'.tmp';fs.writeFileSync(tmp,JSON.stringify(state,null,2));fs.renameSync(tmp,DATA_FILE);}
migrate();
function now(){return Date.now();}
function iso(){return new Date().toISOString();}
function id(prefix){return prefix+'_'+crypto.randomUUID().replaceAll('-','').slice(0,20);}
function cleanCode(x){return String(x||'').trim().toUpperCase().replace(/[^A-Z0-9_-]/g,'').slice(0,64);}
function clampInt(v,min,max){const n=Number(v);return Number.isFinite(n)?Math.max(min,Math.min(max,Math.floor(n))):min;}
function clampNum(v,min,max){const n=Number(v);return Number.isFinite(n)?Math.max(min,Math.min(max,n)):min;}
function audit(action,meta={},actor='system',reason=''){state.audit.unshift({id:id('audit'),at:iso(),actor,action,reason:String(reason||'').slice(0,300),meta});state.audit=state.audit.slice(0,5000);saveState();}
function normalizePlayer(p){
  p.player_id=String(p.player_id||id('player')).slice(0,100); p.name=String(p.name||'ИГРОК').slice(0,20); if(p.coins===undefined)p.coins=120; p.coins=clampInt(p.coins,0,1e9); p.score=clampInt(p.score,0,1e9); p.level=clampInt(p.level||1,1,1000); p.xp=clampInt(p.xp,0,1e9); p.games=clampInt(p.games,0,1e9); p.prizes=clampInt(p.prizes,0,1e9); p.rating=clampInt(p.rating,0,1e9); p.banned=!!p.banned; p.ban_reason=String(p.ban_reason||'').slice(0,500); p.created_at=p.created_at||iso(); p.last_seen=p.last_seen||iso();
  p.inventory=p.inventory&&typeof p.inventory==='object'?p.inventory:{}; p.settings=p.settings&&typeof p.settings==='object'?p.settings:{}; p.collection=p.collection&&typeof p.collection==='object'?p.collection:{}; p.owned_items=Array.isArray(p.owned_items)?p.owned_items:[]; if(!p.owned_items.includes('claw_1'))p.owned_items.push('claw_1'); p.completed_collections=p.completed_collections&&typeof p.completed_collections==='object'?p.completed_collections:{}; p.claimed_achievements=p.claimed_achievements&&typeof p.claimed_achievements==='object'?p.claimed_achievements:{}; p.missions=p.missions&&typeof p.missions==='object'?p.missions:{}; p.read_news=Array.isArray(p.read_news)?p.read_news:[]; p.redeemed=p.redeemed&&typeof p.redeemed==='object'?p.redeemed:{}; p.referrals=Array.isArray(p.referrals)?p.referrals:[]; p.referral_code=p.referral_code||('KHVA'+crypto.createHash('sha256').update(p.player_id).digest('hex').slice(0,8).toUpperCase()); p.referral_used=!!p.referral_used; p.device_ids=Array.isArray(p.device_ids)?p.device_ids:[]; p.notification_cursor=Number(p.notification_cursor||0); p.action_ids=Array.isArray(p.action_ids)?p.action_ids:[]; p.login={...(p.login||{})}; p.season={...(p.season||{}),xp:clampInt(p.season?.xp||0,0,1e9),level:clampInt(p.season?.level||1,1,1000),claimed:Array.isArray(p.season?.claimed)?p.season.claimed:[]};
  p.game=p.game&&typeof p.game==='object'?p.game:{}; if(p.game.current_attempt===undefined)p.game.current_attempt=null; if(p.game.last_attempt_at===undefined)p.game.last_attempt_at=0; p.audit_ids=Array.isArray(p.audit_ids)?p.audit_ids:[];
  return p;
}
function getPlayer(id0,name){const pid=String(id0||'').slice(0,100);if(!pid)return null;if(!state.players[pid]){state.players[pid]=normalizePlayer({player_id:pid,name});audit('player_register',{player_id:pid},'system','new player');}return normalizePlayer(state.players[pid]);}
function publicPlayer(p){const x=JSON.parse(JSON.stringify(p));delete x.action_ids;delete x.audit_ids;return x;}
function activeEvent(){const t=now();return state.events.find(e=>e.enabled!==false&&e.active!==false&&(!e.start_at||Date.parse(e.start_at)<=t)&&(!e.end_at||Date.parse(e.end_at)>t))||null;}
function activeHoliday(){const t=new Date();const md=String(t.getUTCMonth()+1).padStart(2,'0')+'-'+String(t.getUTCDate()).padStart(2,'0');return state.holidays.find(h=>h.enabled!==false&&h.date===md)||null;}
function publicConfig(p){
  const ev=activeEvent(), hol=activeHoliday();
  const unread=state.news.filter(n=>n.published!==false&&(!n.publish_at||Date.parse(n.publish_at)<=now())&&!p?.read_news.includes(n.id)).length;
  return {server_time:Math.floor(now()/1000),maintenance_mode:!!state.settings.maintenance_mode,global_announcement:String(state.settings.global_announcement||''),global_reward_multiplier:Number(state.settings.global_reward_multiplier||1),play_cost:clampInt(state.settings.play_cost,0,1e6),daily_bonus_amount:clampInt(state.settings.daily_bonus_amount,0,1e6),daily_mission_reward:clampInt(state.settings.daily_mission_reward,0,1e6),weekly_mission_reward:clampInt(state.settings.weekly_mission_reward,0,1e6),return_bonus_base:clampInt(state.settings.return_bonus_base,0,1e6),return_bonus_per_day:clampInt(state.settings.return_bonus_per_day,0,1e6),return_bonus_max_days:clampInt(state.settings.return_bonus_max_days,1,90),notification_hours:state.settings.notification_hours,active_event:ev,active_holiday:hol,news:state.news.filter(n=>n.published!==false).slice(-100),unread_news:unread,season:state.season,catalog:state.catalog,missions:state.missions};
}
function leaderboard(){return Object.values(state.players).filter(p=>!p.banned).sort((a,b)=>(b.rating-a.rating)||(b.score-a.score)).slice(0,100).map((p,i)=>({rank:i+1,name:p.name,score:p.score,rating:p.rating,level:p.level,player_id:p.player_id}));}
function grant(p,reward,reason,actionId){const r=reward||{};const type=String(r.type||'coins');const amount=clampInt(r.amount||0,0,1e9);if(amount<=0)return {type,amount:0};if(type==='coins'||type==='rubles')p.coins+=amount;else if(type==='keys')p.inventory.chest_keys=(p.inventory.chest_keys||0)+amount;else if(type==='parts')p.inventory.parts=(p.inventory.parts||0)+amount;else if(type==='xp')p.xp+=amount;else if(type==='rating')p.rating+=amount;else if(type==='chest'){const k=String(r.kind||'common');p.inventory.chests=p.inventory.chests||{};p.inventory.chests[k]=(p.inventory.chests[k]||0)+amount;}else if(type==='item'){p.owned_items.push(String(r.item_id||''));}p.audit_ids.push(actionId||id('op'));audit('reward_grant',{player_id:p.player_id,reward:{type,amount,kind:r.kind,item_id:r.item_id},reason},'server',reason);return {type,amount};}
function missionReset(p){const day=new Date().toISOString().slice(0,10);const week=getISOWeekKey(new Date());p.missions.daily_key=p.missions.daily_key||day;p.missions.weekly_key=p.missions.weekly_key||week;if(p.missions.daily_key!==day){p.missions.daily_key=day;p.missions.daily_progress=0;p.missions.daily_claimed=false;}if(p.missions.weekly_key!==week){p.missions.weekly_key=week;p.missions.weekly_progress=0;p.missions.weekly_claimed=false;}}
function getISOWeekKey(d){const x=new Date(Date.UTC(d.getUTCFullYear(),d.getUTCMonth(),d.getUTCDate()));const day=x.getUTCDay()||7;x.setUTCDate(x.getUTCDate()+4-day);const y=x.getUTCFullYear();const start=new Date(Date.UTC(y,0,1));const w=Math.ceil((((x-start)/86400000)+1)/7);return y+'-W'+String(w).padStart(2,'0');}
function ensurePromoDefaults(){
  if(!state.promocodes.some(x=>cleanCode(x.code)==='KHVA2026'))state.promocodes.push({id:'promo_khva2026',code:'KHVA2026',title:'Стартовый бонус',description:'Бонус нового сезона',reward:{type:'coins',amount:250},starts_at:'',expires_at:'',max_uses:0,used:0,active:true});
  if(!state.promocodes.some(x=>cleanCode(x.code)==='STARTER'))state.promocodes.push({id:'promo_starter',code:'STARTER',title:'Старт',description:'Стартовый подарок',reward:{type:'coins',amount:100},starts_at:'',expires_at:'',max_uses:0,used:0,active:true});
}

function ensureCatalogDefaults(){
  state.catalog.shop=Array.isArray(state.catalog.shop)?state.catalog.shop:[];
  for(let i=0;i<10;i++){const idv='claw_'+(i+1);if(!state.catalog.shop.some(x=>x.id===idv))state.catalog.shop.push({id:idv,category:'claws',name:'КЛЕШНЬ '+(i+1),description:'Улучшенная клешня',price:[0,120,240,420,650,900,1250,1700,2400,3500][i],currency:'coins',level:i+1,effect:{claw_index:i},one_time:true,enabled:true});}
  for(let i=0;i<10;i++){const idv='upgrade_'+(i+1);if(!state.catalog.shop.some(x=>x.id===idv))state.catalog.shop.push({id:idv,category:'upgrades',name:'УЛУЧШЕНИЕ '+(i+1),description:'Уровень '+(i+1),price:[180,220,260,300,340,380,420,470,520,700][i],currency:'coins',level:1,effect:{upgrade_index:i,upgrade_delta:1},one_time:false,enabled:true});}
}

function ensureMissions(){if(!Array.isArray(state.missions.daily)||!state.missions.daily.length)state.missions.daily=[{id:'daily_grab_3',name:'Три игрушки',description:'Получите 3 игрушки',kind:'prizes',target:3,reward:{type:'coins',amount:state.settings.daily_mission_reward},enabled:true,reset:'daily'}];if(!Array.isArray(state.missions.weekly)||!state.missions.weekly.length)state.missions.weekly=[{id:'weekly_grab_12',name:'Недельная охота',description:'Получите 12 игрушек',kind:'prizes',target:12,reward:{type:'coins',amount:state.settings.weekly_mission_reward},enabled:true,reset:'weekly'}];}
ensurePromoDefaults();ensureCatalogDefaults();ensureMissions();saveState();
function rateLimit(key,limit=60,windowMs=60000){const t=now();const a=rate.get(key)||[];const b=a.filter(x=>x>t-windowMs);if(b.length>=limit){rate.set(key,b);return false;}b.push(t);rate.set(key,b);return true;}
function parseAuth(req){const h=String(req.headers.authorization||'');return h.startsWith('Bearer ')?h.slice(7):'';}
function session(token0){const s=sessions.get(token0);if(!s)return null;if(s.expires<now()){sessions.delete(token0);return null;}return s;}
function requirePlayer(req){const s=session(parseAuth(req));return s&&s.kind==='player'?state.players[s.player_id]:null;}
function requireAdmin(req){const s=session(parseAuth(req));return s&&s.kind==='admin'?s:null;}
function json(res,code,obj){const b=JSON.stringify(obj);res.writeHead(code,{'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store','Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'Content-Type, Authorization, Idempotency-Key','Access-Control-Allow-Methods':'GET,POST,PUT,DELETE,OPTIONS'});res.end(b);}
function body(req){return new Promise((resolve,reject)=>{let raw='';req.on('data',c=>{raw+=c;if(raw.length>MAX_BODY){reject(new Error('body too large'));req.destroy();}});req.on('end',()=>{try{resolve(raw?JSON.parse(raw):{});}catch(e){reject(e);}});req.on('error',reject);});}
function actionAlready(p,aid){return !!(aid&&((p.action_ids||[]).includes(aid)||state.actions[aid]));}
function rememberAction(p,aid,result){if(!aid)return;state.actions[aid]={at:iso(),player_id:p.player_id,result};p.action_ids.push(aid);p.action_ids=p.action_ids.slice(-1000);}
function finishResponse(p,extra={}){normalizePlayer(p);saveState();return {ok:true,player:publicPlayer(p),game_state:gameState(p),config:publicConfig(p),leaderboard:leaderboard(),...extra};}
function gameState(p){return {coins:p.coins,score:p.score,level:p.level,xp:p.xp,games:p.games,total_prizes_won:p.prizes,rating:p.rating,inventory:p.inventory,upgrade_levels:p.inventory.upgrade_levels||Array(10).fill(0),selected_claw:p.inventory.selected_claw||0,collection:p.collection,owned_items:p.owned_items,completed_collections:p.completed_collections,claimed_achievements:p.claimed_achievements,missions:p.missions,season:p.season,settings:p.settings,referral_code:p.referral_code,referral_used:p.referral_used,referral_invites:p.referrals.length,banned:p.banned,ban_reason:p.ban_reason};}

function applyXpAndLevels(p, amount){
  p.xp = clampInt((p.xp||0)+Math.max(0,amount),0,1e9);
  const levels=[];
  while(p.xp >= (80 + p.level*20) && p.level < 1000){
    p.xp -= (80 + p.level*20); p.level++; levels.push(p.level);
    p.rating += clampInt(state.settings.rating_level_up,0,100);
  }
  return levels;
}

function recordTransaction(p,before,after,type,actor='server',reason=''){const tx={id:id('tx'),at:iso(),player_id:p.player_id,type,actor,reason,before,after,reversible:true,reversed:false};state.transactions.unshift(tx);state.transactions=state.transactions.slice(0,5000);return tx;}

async function playerAction(req,res,p){
  if(p.banned)return json(res,423,{ok:false,code:'ACCOUNT_BLOCKED',message:'Аккаунт заблокирован',ban_reason:p.ban_reason,contact:'evgeniu.tsepaev19@gmail.com'});
  if(!rateLimit('p:'+p.player_id,120,60000))return json(res,429,{ok:false,message:'Слишком много запросов'});
  const b=await body(req);const type=String(b.type||'');const aid=String(b.action_id||req.headers['idempotency-key']||id('action')).slice(0,120);
  if(actionAlready(p,aid))return json(res,200,{...state.actions[aid].result,idempotent:true});
  let result; const beforeSnapshot=JSON.parse(JSON.stringify(p));
  missionReset(p);
  if(type==='game_start'){
    const cost=clampInt(state.settings.play_cost,0,1e6);if(p.coins<cost)return json(res,409,{ok:false,code:'INSUFFICIENT_FUNDS',message:'Недостаточно рублей'});
    p.coins-=cost;p.games++;const attempt={id:id('attempt'),started_at:now(),resolved:false};
    // The outcome is generated only on the server. Client position/physics never determines the reward.
    const r=Math.random();const chance=clampNum(0.28+Number(p.inventory.capture_bonus||0),0.08,0.90);attempt.success=r<chance;attempt.roll=r;attempt.chance=chance;attempt.toy=state.catalog.toys[Math.floor(Math.random()*state.catalog.toys.length)];attempt.reward=attempt.toy?{type:'coins',amount:rarityReward(attempt.toy.rarity)}:{type:'coins',amount:0};p.game.current_attempt=attempt;p.game.last_attempt_at=now();result=finishResponse(p,{attempt_id:attempt.id,server_result_pending:true});
  } else if(type==='game_finish'){
    const a=p.game.current_attempt;if(!a||a.resolved)return json(res,409,{ok:false,code:'NO_ACTIVE_ATTEMPT',message:'Нет активной игры'});if(now()-a.started_at<500)return json(res,409,{ok:false,code:'TOO_FAST',message:'Игра ещё не завершена'});a.resolved=true;p.game.current_attempt=null;
    if(a.success){const toy=a.toy||{};const reward=grant(p,a.reward,'успешное получение игрушки',aid);p.prizes++;p.score+=3;p.rating+=clampInt(state.settings.rating_success,0,100);p.collection[toy.name||toy.id]=toy.rarity||'ОБЫЧНАЯ';p.inventory.toys=p.inventory.toys||{};p.inventory.toys[toy.id]=(p.inventory.toys[toy.id]||0)+1;const xpGain=xpForRarity(toy.rarity);const levels=applyXpAndLevels(p,xpGain);p.season.xp+=xpGain;const seasonLevels=[];while(p.season.xp>=100&&p.season.level<(state.season.max_level||30)){p.season.xp-=100;p.season.level++;seasonLevels.push(p.season.level);}p.missions.daily_progress=Math.min(missionTarget('daily'),(p.missions.daily_progress||0)+1);p.missions.weekly_progress=Math.min(missionTarget('weekly'),(p.missions.weekly_progress||0)+1);p.inventory.chests=p.inventory.chests||{};const chest=chestForRarity(toy.rarity);p.inventory.chests[chest]=(p.inventory.chests[chest]||0)+1;result=finishResponse(p,{success:true,prize:toy,reward,levels,season_levels:seasonLevels,season:p.season,mission_progress:p.missions});}
    else {result=finishResponse(p,{success:false,prize:null,reward:{type:'none',amount:0},season:p.season,mission_progress:p.missions});}
  } else if(type==='claim_daily'){
    const day=new Date().toISOString().slice(0,10);if(p.login.daily_bonus_date===day)return json(res,409,{ok:false,code:'ALREADY_CLAIMED',message:'Ежедневный бонус уже получен'});p.login.daily_bonus_date=day;const reward=grant(p,{type:'coins',amount:state.settings.daily_bonus_amount},'ежедневный бонус',aid);result=finishResponse(p,{reward});
  } else if(type==='claim_daily_mission'){
    const m=state.missions.daily.find(x=>x.enabled!==false)||{};if((p.missions.daily_progress||0)<missionTarget('daily')||p.missions.daily_claimed)return json(res,409,{ok:false,code:'MISSION_NOT_READY',message:'Миссия ещё не выполнена'});p.missions.daily_claimed=true;const reward=grant(p,m.reward||{type:'coins',amount:state.settings.daily_mission_reward},'ежедневная миссия',aid);result=finishResponse(p,{reward,mission:'daily'});
  } else if(type==='claim_weekly_mission'){
    const m=state.missions.weekly.find(x=>x.enabled!==false)||{};if((p.missions.weekly_progress||0)<missionTarget('weekly')||p.missions.weekly_claimed)return json(res,409,{ok:false,code:'MISSION_NOT_READY',message:'Задание ещё не выполнено'});p.missions.weekly_claimed=true;const reward=grant(p,m.reward||{type:'coins',amount:state.settings.weekly_mission_reward},'недельное задание',aid);result=finishResponse(p,{reward,mission:'weekly'});
  } else if(type==='chest_open'){
    const kind=String(b.kind||'common');p.inventory.chests=p.inventory.chests||{};p.inventory.chest_keys=p.inventory.chest_keys||0;const cfg=state.chests.find(x=>x.id===kind)||defaultChest(kind);const amount=p.inventory.chests[kind]||0;const keyCost=clampInt(cfg.key_cost||1,1,100);if(amount<1)return json(res,409,{ok:false,code:'NO_CHEST',message:'Нет таких сундуков'});if(p.inventory.chest_keys<keyCost)return json(res,409,{ok:false,code:'NO_KEYS',message:'Недостаточно ключей'});p.inventory.chests[kind]--;p.inventory.chest_keys-=keyCost;const rewards=Array.isArray(cfg.rewards)&&cfg.rewards.length?cfg.rewards:[{type:'coins',amount:25},{type:'parts',amount:2}];const picked=weightedReward(rewards);const reward=grant(p,picked,'открытие сундука',aid);p.inventory.chests_opened=(p.inventory.chests_opened||0)+1;result=finishResponse(p,{reward,chest:cfg});
  } else if(type==='shop_buy'){
    const item=state.catalog.shop.find(x=>x.id===String(b.item_id||''));if(!item||item.enabled===false)return json(res,404,{ok:false,message:'Товар недоступен'});const price=clampInt(item.price,0,1e9);if(p.coins<price)return json(res,409,{ok:false,code:'INSUFFICIENT_FUNDS',message:'Недостаточно рублей'});if(item.one_time!==false&&p.owned_items.includes(item.id))return json(res,409,{ok:false,code:'ALREADY_OWNED',message:'Товар уже куплен'});p.coins-=price;p.owned_items.push(item.id);applyEffect(p,item.effect||{});audit('shop_purchase',{player_id:p.player_id,item_id:item.id,price},'server','shop purchase');result=finishResponse(p,{item});
  } else if(type==='shop_select'){
    const itemId=String(b.item_id||'');if(!p.owned_items.includes(itemId))return json(res,403,{ok:false,message:'Предмет не куплен'});p.inventory.selected_skin=itemId;result=finishResponse(p,{selected_item:itemId});
  } else if(type==='promo_redeem'){
    const code=cleanCode(b.code);const pc=state.promocodes.find(x=>cleanCode(x.code)===code);if(!pc||pc.active===false)return json(res,404,{ok:false,message:'Промокод не найден'});if(pc.starts_at&&Date.parse(pc.starts_at)>now())return json(res,409,{ok:false,message:'Промокод ещё не активен'});if(pc.expires_at&&Date.parse(pc.expires_at)<now())return json(res,410,{ok:false,message:'Срок промокода истёк'});if(pc.max_uses>0&&(pc.used||0)>=pc.max_uses)return json(res,409,{ok:false,message:'Лимит активаций исчерпан'});if(p.redeemed[code])return json(res,409,{ok:false,code:'ALREADY_REDEEMED',message:'Промокод уже активирован'});p.redeemed[code]=iso();pc.used=(pc.used||0)+1;const reward=grant(p,pc.reward||{type:'coins',amount:0},'промокод '+code,aid);result=finishResponse(p,{promo:{code,title:pc.title||code,description:pc.description||'',reward}});
  } else if(type==='referral_apply'){
    const code=cleanCode(b.referral_code);if(p.referral_used)return json(res,409,{ok:false,message:'Реферальный код уже активирован'});const inviter=Object.values(state.players).find(x=>cleanCode(x.referral_code)===code&&x.player_id!==p.player_id);if(!inviter)return json(res,404,{ok:false,message:'Реферальный код не найден'});if(inviter.referrals.includes(p.player_id))return json(res,409,{ok:false,message:'Игрок уже привязан'});p.referral_used=true;p.referred_by=inviter.player_id;p.referrals=[];inviter.referrals.push(p.player_id);const rr=grant(p,{type:'coins',amount:50},'реферальный бонус приглашённому',aid);grant(inviter,{type:'coins',amount:100},'реферальный бонус пригласившему',id('ref'));result=finishResponse(p,{reward:rr,inviter_reward:100});
  } else if(type==='news_read'){
    const newsId=String(b.news_id||'');if(state.news.some(n=>n.id===newsId)&&!p.read_news.includes(newsId))p.read_news.push(newsId);result=finishResponse(p,{unread_news:state.news.filter(n=>n.published!==false&&!p.read_news.includes(n.id)).length});
  } else if(type==='settings_update'){
    const allowed=['music','sfx','sfx_volume_db','music_volume_db','vibration_on','energy_saving_on','confirm_purchases_on','confirm_rare_chests_on','fps_limit','joystick_sensitivity','grab_button_scale','auto_tips_on','notifications_on','notify_rewards_on','notify_streak_on','notify_events_on','notify_workshop_on','notify_chests_on','quality_level','language'];p.settings=p.settings||{};for(const k of allowed)if(b.settings&&Object.prototype.hasOwnProperty.call(b.settings,k))p.settings[k]=b.settings[k];result=finishResponse(p,{settings:p.settings});
  } else if(type==='season_xp'){
    const amount=clampInt(b.amount||0,0,100);if(amount<=0)return json(res,400,{ok:false,message:'Некорректный XP'});p.season.xp+=amount;const max=clampInt(state.season.max_level||30,1,1000);const levels=[];while(p.season.xp>=100&&p.season.level<max){p.season.xp-=100;p.season.level++;levels.push(p.season.level);}result=finishResponse(p,{levels});
  } else if(type==='season_claim'){
    const level=clampInt(b.level,1,1000);if(level>p.season.level||p.season.claimed.includes(level))return json(res,409,{ok:false,message:'Награда недоступна'});const row=(state.season.levels||[]).find(x=>Number(x.level)===level);if(!row)return json(res,404,{ok:false,message:'Награда не настроена'});p.season.claimed.push(level);const reward=grant(p,row.reward||parseRewardText(row.type,row.reward),'награда сезонного пропуска',aid);result=finishResponse(p,{reward,level});
  } else if(type==='collection_claim'){
    const c=state.catalog.collections.find(x=>x.id===String(b.collection_id||''));if(!c)return json(res,404,{ok:false,message:'Коллекция не найдена'});if(p.completed_collections[c.id])return json(res,409,{ok:false,message:'Награда уже получена'});if(!c.toy_ids.every(t=>p.collection[state.catalog.toys.find(x=>x.id===t)?.name]))return json(res,409,{ok:false,message:'Коллекция не завершена'});p.completed_collections[c.id]=iso();const reward=grant(p,c.reward,'полная коллекция '+c.name,aid);result=finishResponse(p,{reward,collection:c});
  } else if(type==='achievement_claim'){
    const a=state.catalog.achievements.find(x=>x.id===String(b.achievement_id||''));if(!a)return json(res,404,{ok:false,message:'Достижение не найдено'});if(p.claimed_achievements[a.id])return json(res,409,{ok:false,message:'Награда уже получена'});if(achievementValue(p,a.kind)<a.value)return json(res,409,{ok:false,message:'Достижение ещё не выполнено'});p.claimed_achievements[a.id]=iso();const reward=grant(p,a.reward,'достижение '+a.name,aid);result=finishResponse(p,{reward,achievement:a});
  } else if(type==='return_bonus'){
    const days=clampInt(b.days||0,0,90);const reward=grant(p,{type:'coins',amount:state.settings.return_bonus_base+Math.min(days,state.settings.return_bonus_max_days)*state.settings.return_bonus_per_day},'бонус возвращения',aid);result=finishResponse(p,{reward});
  } else if(type==='admin_override'){return json(res,403,{ok:false,message:'Недоступно'});}
  else return json(res,404,{ok:false,message:'Неизвестное действие'});
  const tx=recordTransaction(p,beforeSnapshot,JSON.parse(JSON.stringify(p)),type,'server','Игровая операция');
  if(result&&typeof result==='object')result.transaction_id=tx.id;
  rememberAction(p,aid,result);saveState();return json(res,200,result);
}
function missionTarget(kind){ensureMissions();const m=(kind==='daily'?state.missions.daily:state.missions.weekly).find(x=>x.enabled!==false);return clampInt(m?.target|| (kind==='daily'?3:12),1,100000);}
function rarityReward(r){return {ОБЫЧНАЯ:10,НЕОБЫЧНАЯ:20,РЕДКАЯ:40,ЭПИЧЕСКАЯ:80,ЛЕГЕНДАРНАЯ:160,МИФИЧЕСКАЯ:300}[r]||10;}
function xpForRarity(r){return {ОБЫЧНАЯ:10,НЕОБЫЧНАЯ:15,РЕДКАЯ:25,ЭПИЧЕСКАЯ:40,ЛЕГЕНДАРНАЯ:65,МИФИЧЕСКАЯ:100}[r]||10;}
function chestForRarity(r){return r==='МИФИЧЕСКАЯ'?'legendary':r==='ЛЕГЕНДАРНАЯ'?'epic':r==='ЭПИЧЕСКАЯ'?'rare':'common';}
function defaultChest(kind){return {id:kind,name:kind.toUpperCase()+' СУНДУК',key_cost:{common:1,rare:2,epic:3,legendary:5,vip:8}[kind]||1,rewards:[{type:'coins',amount:{common:25,rare:100,epic:300,legendary:700,vip:1500}[kind]||25},{type:'parts',amount:{common:2,rare:5,epic:10,legendary:20,vip:30}[kind]||2}],enabled:true};}
function weightedReward(a){const total=a.reduce((s,x)=>s+Math.max(0,Number(x.weight??1)),0);let r=Math.random()*Math.max(total,1);for(const x of a){r-=Math.max(0,Number(x.weight??1));if(r<=0)return x;}return a[0]||{type:'coins',amount:0};}
function applyEffect(p,e){if(e.capture_bonus)p.inventory.capture_bonus=Number(p.inventory.capture_bonus||0)+Number(e.capture_bonus);if(e.game_time)p.inventory.game_time=Number(p.inventory.game_time||0)+Number(e.game_time);if(e.skin)p.inventory.selected_skin=e.skin;if(e.claw_index!==undefined)p.inventory.selected_claw=clampInt(e.claw_index,0,9);if(e.upgrade_index!==undefined){p.inventory.upgrade_levels=p.inventory.upgrade_levels||Array(10).fill(0);const i=clampInt(e.upgrade_index,0,9);p.inventory.upgrade_levels[i]=clampInt((p.inventory.upgrade_levels[i]||0)+clampInt(e.upgrade_delta||1,1,1),0,20);}}
function parseRewardText(type,text){const n=parseInt(String(text||'').replace(/[^0-9]/g,''),10)||0;return {type:type==='ключи'?'keys':type==='детали'?'parts':type==='XP'?'xp':'coins',amount:n};}
function achievementValue(p,k){return k==='prizes'?p.prizes:k==='chests_opened'?(p.inventory.chests_opened||0):k==='referrals'?p.referrals.length:k==='games'?p.games:k==='rating'?p.rating:p.level;}

async function handle(req,res){
  if(req.method==='OPTIONS'){res.writeHead(204,{'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'Content-Type, Authorization, Idempotency-Key','Access-Control-Allow-Methods':'GET,POST,PUT,DELETE,OPTIONS'});return res.end();}
  const u=new URL(req.url,'http://'+(req.headers.host||'localhost'));const pth=u.pathname;
  if(!rateLimit('ip:'+req.socket.remoteAddress,300,60000))return json(res,429,{ok:false,message:'Слишком много запросов'});
  if(pth==='/health')return json(res,200,{ok:true,service:'khvataika',schema:state.schema_version,time:iso()});
  if(pth==='/api/config'&&req.method==='GET'){const pid=u.searchParams.get('player_id');const p=pid?getPlayer(pid,u.searchParams.get('name')):null;return json(res,200,{ok:true,player:p?publicPlayer(p):null,game_state:p?gameState(p):{},config:publicConfig(p),leaderboard:leaderboard()});}
  if(pth==='/api/rating'&&req.method==='GET')return json(res,200,{ok:true,leaderboard:leaderboard()});
  if(pth==='/api/player/register'&&req.method==='POST'){const b=await body(req);const p=getPlayer(b.player_id,b.name);p.last_seen=iso();const t=crypto.randomBytes(32).toString('hex');sessions.set(t,{kind:'player',player_id:p.player_id,expires:now()+PLAYER_SESSION_TTL});saveState();return json(res,200,{ok:true,token:t,player:publicPlayer(p),game_state:gameState(p),config:publicConfig(p),leaderboard:leaderboard()});}
  if(pth==='/api/player/action'&&req.method==='POST'){const p=requirePlayer(req);if(!p)return json(res,401,{ok:false,message:'Требуется авторизация игрока'});return playerAction(req,res,p);}
  if(pth==='/api/player/sync'&&req.method==='POST'){const p=requirePlayer(req);if(!p)return json(res,401,{ok:false,message:'Старая синхронизация отключена. Выполните регистрацию.'});p.last_seen=iso();return json(res,200,finishResponse(p));}
  if(pth==='/api/player/bootstrap'&&req.method==='GET'){const p=requirePlayer(req);if(!p)return json(res,401,{ok:false,message:'Требуется авторизация'});p.last_seen=iso();return json(res,200,finishResponse(p));}
  if(pth==='/api/notifications/poll'&&req.method==='GET'){const pid=String(u.searchParams.get('player_id')||'');const p=getPlayer(pid);if(!p)return json(res,400,{ok:false,message:'player_id required'});const cursor=Number(u.searchParams.get('cursor')||p.notification_cursor);const items=state.notifications.filter(n=>Number(n.id_num||0)>cursor&&(n.target==='all'||n.target===p.player_id)&&(!n.deliver_at||Date.parse(n.deliver_at)<=now())&&!n.cancelled).sort((a,b)=>(a.id_num||0)-(b.id_num||0)).slice(0,50);if(items.length){p.notification_cursor=Math.max(cursor,...items.map(x=>Number(x.id_num||0)));for(const n of items){state.notification_history.push({notification_id:n.id,player_id:p.player_id,status:'delivered',delivered_at:iso()});}state.notification_history=state.notification_history.slice(-5000);}saveState();return json(res,200,{ok:true,notifications:items,next_cursor:p.notification_cursor,server_time:Math.floor(now()/1000)});}
  if(pth==='/api/device/register'&&req.method==='POST'){const p=requirePlayer(req)||getPlayer((await body(req)).player_id);return json(res,200,{ok:true});}
  if(pth==='/api/admin/login'&&req.method==='POST'){if(!ADMIN_PASSWORD)return json(res,503,{ok:false,message:'ADMIN_PASSWORD не задан на сервере'});const b=await body(req);if(String(b.password||'')!==ADMIN_PASSWORD)return json(res,401,{ok:false,message:'Неверный пароль'});const t=crypto.randomBytes(32).toString('hex');sessions.set(t,{kind:'admin',admin:'admin',expires:now()+ADMIN_SESSION_TTL});return json(res,200,{ok:true,token:t});}
  if(pth.startsWith('/api/admin/'))return adminHandle(req,res,pth);
  if(pth==='/'||pth==='/index.html'){const html=fs.readFileSync(path.join(__dirname,'public','index.html'));res.writeHead(200,{'Content-Type':'text/html; charset=utf-8'});return res.end(html);}
  return json(res,404,{ok:false,message:'Not found'});
}
async function adminHandle(req,res,pth){
  const adm=requireAdmin(req);if(!adm)return json(res,401,{ok:false,message:'Требуется вход администратора'});if(!rateLimit('admin:'+adm.admin,300,60000))return json(res,429,{ok:false,message:'Слишком много запросов'});
  if(pth==='/api/admin/state'&&req.method==='GET')return json(res,200,{ok:true,state});
  if(pth==='/api/admin/dashboard'&&req.method==='GET'){const ps=Object.values(state.players);return json(res,200,{ok:true,stats:{players:ps.length,online:ps.filter(p=>now()-Date.parse(p.last_seen)<300000).length,banned:ps.filter(p=>p.banned).length,coins:ps.reduce((s,p)=>s+p.coins,0),games:ps.reduce((s,p)=>s+p.games,0),prizes:ps.reduce((s,p)=>s+p.prizes,0)},recent_audit:state.audit.slice(0,50),notifications:state.notifications.slice(-20).reverse()});}
  if(pth==='/api/admin/state'&&req.method==='POST'){const b=await body(req);const reason=String(b.reason||'Изменение конфигурации');const beforeNews=JSON.stringify(state.news);for(const k of ['settings','promocodes','news','events','holidays','season','chests','missions','catalog'])if(b[k]!==undefined)state[k]=b[k];state.settings={...DEFAULT_SETTINGS,...state.settings,notification_hours:{...DEFAULT_SETTINGS.notification_hours,...(state.settings.notification_hours||{})}};if(b.news!==undefined && JSON.stringify(state.news)!==beforeNews){for(const n of state.news.filter(x=>x.published!==false)){if(!n.notified){queueNewsNotification(n);n.notified=true;}}}audit('admin_state_update',{sections:Object.keys(b).filter(k=>k!=='reason')},adm.admin,reason);saveState();return json(res,200,{ok:true,state});}
  if(pth==='/api/admin/player'&&req.method==='POST'){const b=await body(req);const p=state.players[String(b.player_id||'')];if(!p)return json(res,404,{ok:false,message:'Игрок не найден'});const reason=String(b.reason||'Изменение администратора');const before=JSON.parse(JSON.stringify(p));switch(b.action){case'ban':p.banned=true;p.ban_reason=reason;break;case'unban':p.banned=false;p.ban_reason='';break;case'set_coins':p.coins=clampInt(b.coins,0,1e9);break;case'set_rating':p.rating=clampInt(b.rating,0,1e9);break;case'grant':grant(p,b.reward||{},'администратор',id('admin'));break;case'revoke':{const amt=clampInt(b.amount,0,1e9);p.coins=Math.max(0,p.coins-amt);break;}case'reset_progress':p.collection={};p.completed_collections={};p.claimed_achievements={};p.missions={};p.season={xp:0,level:1,claimed:[]};break;default:return json(res,400,{ok:false,message:'Неизвестное действие'});}const tx=recordTransaction(p,before,JSON.parse(JSON.stringify(p)),'admin_'+b.action,adm.admin,reason);audit('admin_player_change',{player_id:p.player_id,action:b.action,transaction_id:tx.id},adm.admin,reason);saveState();return json(res,200,{ok:true,player:publicPlayer(p),transaction_id:tx.id});}
  if(pth==='/api/admin/notify'&&req.method==='POST'){const b=await body(req);const n={id:id('notification'),id_num:Date.now()+Math.floor(Math.random()*1000),target:String(b.player_id||'all'),title:String(b.title||'Хватайка').slice(0,120),message:String(b.message||'').slice(0,1000),kind:String(b.kind||'general').slice(0,50),icon:String(b.icon||'assets/1000088915.png').slice(0,300),deliver_at:b.deliver_at||'',event_id:String(b.event_id||''),enabled:b.enabled!==false,created_at:iso(),created_by:adm.admin};state.notifications.push(n);state.notification_history.push({...n,status:'queued'});state.notification_history=state.notification_history.slice(-5000);state.notifications=state.notifications.slice(-2000);audit('notification_create',{notification_id:n.id,target:n.target},adm.admin,String(b.reason||'Создание уведомления'));saveState();return json(res,200,{ok:true,notification:n});}
  if(pth==='/api/admin/notifications'&&req.method==='GET')return json(res,200,{ok:true,notifications:state.notifications.slice(-500).reverse(),history:state.notification_history.slice(-500).reverse()});
  if(pth==='/api/admin/notification'&&req.method==='POST'){const b=await body(req);const n=state.notifications.find(x=>x.id===b.id);if(!n)return json(res,404,{ok:false});Object.assign(n,{title:b.title!==undefined?String(b.title):n.title,message:b.message!==undefined?String(b.message):n.message,target:b.target!==undefined?String(b.target):n.target,deliver_at:b.deliver_at!==undefined?b.deliver_at:n.deliver_at,enabled:b.enabled!==undefined?!!b.enabled:n.enabled,icon:b.icon!==undefined?String(b.icon):n.icon,kind:b.kind!==undefined?String(b.kind):n.kind});audit('notification_update',{id:n.id},adm.admin,String(b.reason||'Изменение уведомления'));saveState();return json(res,200,{ok:true,notification:n});}
  if(pth==='/api/admin/notification/delete'&&req.method==='POST'){const b=await body(req);state.notifications=state.notifications.filter(x=>x.id!==b.id);audit('notification_delete',{id:b.id},adm.admin,String(b.reason||'Удаление уведомления'));saveState();return json(res,200,{ok:true});}
  if(pth==='/api/admin/news/publish'&&req.method==='POST'){const b=await body(req);const n=state.news.find(x=>x.id===b.id);if(!n)return json(res,404,{ok:false});n.published=!!b.published;if(n.published&&!n.notified){queueNewsNotification(n);n.notified=true;}audit('news_publish',{id:n.id,published:n.published},adm.admin,String(b.reason||'Публикация новости'));saveState();return json(res,200,{ok:true,news:n});}
  if(pth==='/api/admin/audit'&&req.method==='GET'){const limit=clampInt(uLimit(req),1,500);return json(res,200,{ok:true,audit:state.audit.slice(0,limit)});}
  if(pth==='/api/admin/transactions'&&req.method==='GET')return json(res,200,{ok:true,transactions:state.transactions.slice(0,500)});
  if(pth==='/api/admin/transaction/reverse'&&req.method==='POST'){const b=await body(req);const tx=state.transactions.find(x=>x.id===b.transaction_id);if(!tx)return json(res,404,{ok:false,message:'Операция не найдена'});if(!tx.reversible||tx.reversed)return json(res,409,{ok:false,message:'Операцию уже нельзя отменить'});const p=state.players[tx.player_id];if(!p)return json(res,404,{ok:false,message:'Игрок не найден'});state.players[tx.player_id]=JSON.parse(JSON.stringify(tx.before));tx.reversed=true;tx.reversed_at=iso();tx.reversed_by=adm.admin;audit('transaction_reverse',{transaction_id:tx.id,player_id:tx.player_id},adm.admin,String(b.reason||'Отмена операции'));saveState();return json(res,200,{ok:true,player:publicPlayer(state.players[tx.player_id])});}
  if(pth==='/api/admin/rollback'&&req.method==='POST'){const b=await body(req);return json(res,409,{ok:false,message:'Автоматический rollback доступен только для операций с обратимой транзакцией; используйте журнал и обратную операцию игрока.',action_id:b.action_id||''});}
  return json(res,404,{ok:false,message:'Unknown admin endpoint'});
}
function uLimit(req){try{return Number(new URL(req.url,'http://x').searchParams.get('limit')||100);}catch{return 100;}}
function queueNewsNotification(n){state.notifications.push({id:id('notification'),id_num:Date.now()+Math.floor(Math.random()*1000),target:'all',title:n.title,message:n.text,kind:'news',icon:'assets/1000088915.png',deliver_at:'',enabled:true,created_at:iso(),created_by:'server'});}
function systemScheduler(){
  const day=new Date().toISOString().slice(0,10);
  if(state.system_marks.daily_mission_day!==day){state.system_marks.daily_mission_day=day;ensureMissions();queueNotification('all','🎯 Новые ежедневные миссии','Доступны новые ежедневные миссии. Проверь задания!','mission');}
  const week=getISOWeekKey(new Date());
  if(state.system_marks.weekly_mission_week!==week){state.system_marks.weekly_mission_week=week;ensureMissions();queueNotification('all','🏆 Новое недельное задание','Началась новая неделя — доступно новое задание!','mission');}
  const ev=activeEvent(); const evId=ev?String(ev.id):''; if(evId!==String(state.system_marks.active_event_id||'')){state.system_marks.active_event_id=evId;if(ev)queueNotification('all','⚡ Новое событие',String(ev.name||'Событие')+' уже активно.','event');}
  const hol=activeHoliday(); const holId=hol?String(hol.id||hol.date):''; if(holId!==String(state.system_marks.active_holiday_id||'')){state.system_marks.active_holiday_id=holId;if(hol)queueNotification('all','🎉 Праздник',String(hol.name||'Праздничный бонус')+' уже активен.','holiday');}
  saveState();
}
function queueNotification(target,title,message,kind='general',deliverAt=''){const n={id:id('notification'),id_num:Date.now()+Math.floor(Math.random()*1000),target:String(target||'all'),title:String(title||'Хватайка').slice(0,120),message:String(message||'').slice(0,1000),kind:String(kind||'general'),icon:'assets/1000088915.png',deliver_at:deliverAt,enabled:true,created_at:iso(),created_by:'server'};state.notifications.push(n);state.notifications=state.notifications.slice(-2000);return n;}
systemScheduler();setInterval(()=>{for(const [t,s] of sessions)if(s.expires<now())sessions.delete(t);systemScheduler();},60000);
http.createServer((req,res)=>handle(req,res).catch(e=>{console.error(e);json(res,500,{ok:false,message:'server error'});})).listen(PORT,()=>console.log(`Хватайка authoritative server: 0.0.0.0:${PORT}`));
