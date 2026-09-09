const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { URL } = require('url');

const PORT = Number(process.env.PORT || 8080);
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'change-me-now';
const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, 'data');
const DATA_FILE = path.join(DATA_DIR, 'state.json');
const sessions = new Map();

function loadState(){
  try { return JSON.parse(fs.readFileSync(DATA_FILE,'utf8')); }
  catch(e){ return {settings:{},promocodes:[],news:[],events:[],season:{name:'Сезон 1',max_level:30,levels:[]},chests:[],notifications:[],players:{},audit:[]}; }
}
let state = loadState();
state.notifications = Array.isArray(state.notifications) ? state.notifications : [];
for (const p of Object.values(state.players || {})) {
  p.device_ids = Array.isArray(p.device_ids) ? p.device_ids : [];
  p.notification_cursor = Number(p.notification_cursor || 0);
  p.game_state = (p.game_state && typeof p.game_state === 'object') ? p.game_state : {};
}
function saveState(){ fs.mkdirSync(path.dirname(DATA_FILE),{recursive:true}); fs.writeFileSync(DATA_FILE, JSON.stringify(state,null,2)); }
function json(res, code, obj){ const body=JSON.stringify(obj); res.writeHead(code, {'Content-Type':'application/json; charset=utf-8','Access-Control-Allow-Origin':'*','Cache-Control':'no-store'}); res.end(body); }
function body(req){ return new Promise((resolve,reject)=>{ let raw=''; req.on('data',c=>{raw+=c; if(raw.length>1024*1024) req.destroy();}); req.on('end',()=>{try{resolve(raw?JSON.parse(raw):{});}catch(e){reject(e);}}); req.on('error',reject); }); }
function audit(action, meta={}){ state.audit.unshift({at:new Date().toISOString(),action,meta}); state.audit=state.audit.slice(0,500); saveState(); }
function auth(req){ const h=req.headers.authorization||''; return h.startsWith('Bearer ') && sessions.has(h.slice(7)); }
function token(){ return crypto.randomBytes(24).toString('hex'); }
function cleanCode(x){ return String(x||'').trim().toUpperCase().replace(/[^A-Z0-9_-]/g,''); }
function publicConfig(){
  const now=Date.now();
  const activeEvent=(state.events||[]).find(e=>e.active && (!e.end_unix || e.end_unix*1000>now)) || null;
  return { ...state.settings, news:(state.news||[]).slice(0,100), active_event:activeEvent, server_time:Math.floor(now/1000) };
}
function leaderboard(){
  return Object.values(state.players||{}).filter(p=>!p.banned).sort((a,b)=>(b.score||0)-(a.score||0)).slice(0,50).map((p,i)=>({rank:i+1,name:p.name||'ИГРОК',score:p.score||0,level:p.level||1,player_id:p.player_id}));
}
function normalizeSettings(s){
  const out={...state.settings,...(s||{})};
  out.maintenance_mode=!!out.maintenance_mode;
  out.global_announcement=String(out.global_announcement||'').slice(0,500);
  for(const k of ['global_reward_multiplier']) out[k]=Math.min(10,Math.max(0.1,Number(out[k]||1)));
  for(const k of ['daily_bonus_amount','daily_mission_reward','weekly_mission_reward','return_bonus_base','return_bonus_per_day']) out[k]=Math.max(0,Math.floor(Number(out[k]||0)));
  out.return_bonus_max_days=Math.min(90,Math.max(1,Math.floor(Number(out.return_bonus_max_days||30))));
  const nh=out.notification_hours||{}; out.notification_hours={rewards:Math.min(23,Math.max(0,Math.floor(Number(nh.rewards??12)))),streak:Math.min(23,Math.max(0,Math.floor(Number(nh.streak??20)))),chests:Math.min(23,Math.max(0,Math.floor(Number(nh.chests??18))))};
  return out;
}
function makeReferralCode(id){
  const digest=crypto.createHash('sha256').update(String(id)).digest('hex').slice(0,8).toUpperCase();
  return 'KHVA' + digest;
}
function getOrCreatePlayer(id,name='ИГРОК'){
  id=String(id||'').slice(0,80);
  if(!id) return null;
  let p=state.players[id];
  if(!p){
    p={player_id:id,name:String(name||'ИГРОК').slice(0,20),score:0,level:1,coins:120,games:0,prizes:0,best_streak:0,last_seen:new Date().toISOString(),banned:false,referral_code:makeReferralCode(id),referral_invites:0,referral_used:false,referrals:[],redeemed:{},device_ids:[],notification_cursor:0,game_state:{}};
    state.players[id]=p;
    audit('player_register',{player_id:id});
  }else{
    p.referral_code=p.referral_code||makeReferralCode(id);
    p.referral_invites=Math.max(0,Math.floor(Number(p.referral_invites||0)));
    p.referral_used=!!p.referral_used;
    p.referrals=Array.isArray(p.referrals)?p.referrals:[];
    p.redeemed=p.redeemed||{};
    p.device_ids=Array.isArray(p.device_ids)?p.device_ids:[];
    p.notification_cursor=Number(p.notification_cursor||0);
    p.game_state=(p.game_state&&typeof p.game_state==='object')?p.game_state:{};
  }
  return p;
}

function safeGameState(x){
  if(!x || typeof x!=='object') return {};
  const out={...x};
  const clamp=(v,max=100000000)=>Math.max(0,Math.min(max,Math.floor(Number(v||0))));
  for(const k of ['coins','bonus_keys','engineering_parts','chest_keys','total_chests_opened','total_keys_earned','total_daily_claims','total_weekly_claims','workshop_parts','workshop_level','workshop_claw_power','workshop_speed','workshop_precision','workshop_luck','workshop_motor','workshop_servo','workshop_cable','workshop_damper','workshop_cooling','workshop_controller','workshop_calibration','workshop_overclock_games','level','xp','xp_to_next','games','total_prizes_won','best_win_streak','current_win_streak','total_xp_earned','highest_reward_rubles','perfect_grabs','heavy_toy_wins','lucky_toy_wins','daily_mission_progress','weekly_mission_progress','season_pass_xp','season_pass_level']) if(out[k]!==undefined) out[k]=clamp(out[k]);
  if(out.player_name!==undefined) out.player_name=String(out.player_name).slice(0,20);
  if(out.collection && typeof out.collection==='object') out.collection=out.collection;
  if(out.toy_inventory_counts && typeof out.toy_inventory_counts==='object') out.toy_inventory_counts=out.toy_inventory_counts;
  return out;
}
function queueNotification(target,title,message,kind='general',deliver_at=0){
  const n={id:Date.now()+Math.floor(Math.random()*1000),target:String(target||'all'),title:String(title||'Хватайка').slice(0,120),message:String(message||'Зайди в игру!').slice(0,500),kind:String(kind||'general').slice(0,40),deliver_at:Number(deliver_at||0),created_at:new Date().toISOString()};
  state.notifications.push(n); state.notifications=state.notifications.slice(-1000); saveState(); audit('notification_queue',{target:n.target,kind:n.kind,title:n.title}); return n;
}
function pendingNotifications(player,afterId){
  const now=Date.now(); const cursor=Number(afterId||0);
  return state.notifications.filter(n=>(Number(n.id)>cursor) && (!n.deliver_at || Number(n.deliver_at)<=now) && (n.target==='all' || n.target===player.player_id)).sort((a,b)=>Number(a.id)-Number(b.id)).slice(0,30);
}

async function handle(req,res){
  if(req.method==='OPTIONS'){res.writeHead(204,{'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'Content-Type, Authorization','Access-Control-Allow-Methods':'GET,POST,OPTIONS'});return res.end();}
  const u=new URL(req.url,`http://${req.headers.host}`); const p=u.pathname;
  if(p==='/health') return json(res,200,{ok:true,service:'khvataika',time:new Date().toISOString()});
  if(p==='/api/config' && req.method==='GET'){
    const id=String(u.searchParams.get('player_id')||'').trim();
    const name=String(u.searchParams.get('name')||'ИГРОК');
    let player=null;
    if(id){ player=getOrCreatePlayer(id,name); saveState(); }
    return json(res,200,{ok:true,player,game_state:player?player.game_state:{},config:publicConfig(),leaderboard:leaderboard(),notifications:player?pendingNotifications(player,player.notification_cursor):[]});
  }
  if(p==='/api/rating' && req.method==='GET') return json(res,200,{ok:true,leaderboard:leaderboard()});
  if(p==='/api/player/register' && req.method==='POST'){
    try{
      const b=await body(req); const id=String(b.player_id||'').slice(0,80); if(!id) return json(res,400,{ok:false,message:'player_id required'});
      const player=getOrCreatePlayer(id,b.name); player.name=String(b.name||player.name||'ИГРОК').slice(0,20); player.last_seen=new Date().toISOString();
      saveState(); return json(res,200,{ok:true,player,leaderboard:leaderboard()});
    }catch(e){return json(res,400,{ok:false,message:'bad json'});}
  }
  if(p==='/api/player/sync' && req.method==='POST'){
    try{
      const b=await body(req); const id=String(b.player_id||'').slice(0,80); if(!id) return json(res,400,{ok:false,message:'player_id required'});
      const player=getOrCreatePlayer(id,b.name);
      if(player.banned) return json(res,403,{ok:false,message:'Аккаунт ограничен'});
      const override=player.admin_coins_override;
      player.name=String(b.name||player.name||'ИГРОК').slice(0,20);
      player.level=Math.max(1,Math.floor(Number(b.level||player.level||1)));
      player.coins=override!==undefined?Math.max(0,Math.floor(Number(override))):Math.max(0,Math.floor(Number(b.coins||0)));
      player.games=Math.max(0,Math.floor(Number(b.games||0)));
      player.prizes=Math.max(0,Math.floor(Number(b.prizes||0)));
      player.best_streak=Math.max(0,Math.floor(Number(b.best_streak||player.best_streak||0)));
      player.score=Math.max(0,Math.floor(Number(b.score||0)));
      if(b.game_state && typeof b.game_state==='object') player.game_state=safeGameState(b.game_state);
      player.last_seen=new Date().toISOString();
      if(override!==undefined) delete player.admin_coins_override;
      player.referral_code=player.referral_code||makeReferralCode(id);
      // referral_invites/referrals являются серверными данными и не принимаются от клиента,
      // чтобы приложение не могло случайно перезаписать счётчик приглашений.
      state.players[id]=player;
      saveState();
      return json(res,200,{ok:true,player,game_state:player.game_state,config:publicConfig(),leaderboard:leaderboard(),notifications:pendingNotifications(player,player.notification_cursor)});
    }catch(e){return json(res,400,{ok:false,message:'bad json'});}
  }
  if(p==='/api/referral/apply' && req.method==='POST'){
    try{
      const b=await body(req); const id=String(b.player_id||'').slice(0,80); const code=cleanCode(b.referral_code);
      if(!id||!code) return json(res,400,{ok:false,message:'Нужны игрок и реферальный код'});
      const player=getOrCreatePlayer(id,b.name); if(player.banned) return json(res,403,{ok:false,message:'Аккаунт ограничен'});
      if(player.referral_used) return json(res,409,{ok:false,message:'Реферальный код уже активирован'});
      const inviter=Object.values(state.players).find(x=>cleanCode(x.referral_code)===code && x.player_id!==id);
      if(!inviter) return json(res,404,{ok:false,message:'Реферальный код не найден'});
      if(Array.isArray(inviter.referrals) && inviter.referrals.includes(id)) return json(res,409,{ok:false,message:'Игрок уже привязан'});
      player.referral_used=true; player.referred_by=inviter.player_id; player.coins=Math.max(0,Number(player.coins||0))+50;
      inviter.referrals=Array.isArray(inviter.referrals)?inviter.referrals:[]; inviter.referrals.push(id); inviter.referral_invites=inviter.referrals.length; inviter.coins=Math.max(0,Number(inviter.coins||0))+100;
      state.players[id]=player; state.players[inviter.player_id]=inviter; saveState(); audit('referral_apply',{player_id:id,inviter_id:inviter.player_id});
      return json(res,200,{ok:true,reward:50,inviter_reward:100,player,leaderboard:leaderboard()});
    }catch(e){return json(res,400,{ok:false,message:'bad json'});}
  }
  if(p==='/api/device/register' && req.method==='POST'){
    try{ const b=await body(req); const id=String(b.player_id||'').slice(0,80); const device=String(b.device_id||'').slice(0,160); if(!id||!device) return json(res,400,{ok:false,message:'player_id и device_id обязательны'}); const player=getOrCreatePlayer(id,b.name); player.device_ids=Array.isArray(player.device_ids)?player.device_ids:[]; if(!player.device_ids.includes(device)) player.device_ids.push(device); player.device_ids=player.device_ids.slice(-5); player.last_seen=new Date().toISOString(); saveState(); return json(res,200,{ok:true,player_id:id,device_id:device,server_time:Math.floor(Date.now()/1000)}); }catch(e){return json(res,400,{ok:false,message:'bad json'});}
  }
  if(p==='/api/notifications/poll' && req.method==='GET'){
    const id=String(u.searchParams.get('player_id')||'').trim(); const cursor=Number(u.searchParams.get('cursor')||0); if(!id) return json(res,400,{ok:false,message:'player_id required'}); const player=getOrCreatePlayer(id); const items=pendingNotifications(player,cursor); if(items.length){player.notification_cursor=Math.max(player.notification_cursor,Math.max(...items.map(x=>Number(x.id)))); player.last_seen=new Date().toISOString(); saveState();} return json(res,200,{ok:true,notifications:items,server_time:Math.floor(Date.now()/1000),next_cursor:Math.max(cursor,player.notification_cursor)});
  }
  if(p==='/api/notifications/ack' && req.method==='POST'){
    try{const b=await body(req); const id=String(b.player_id||'').slice(0,80); const cursor=Number(b.cursor||0); if(!id)return json(res,400,{ok:false,message:'player_id required'}); const player=getOrCreatePlayer(id); player.notification_cursor=Math.max(Number(player.notification_cursor||0),cursor); saveState(); return json(res,200,{ok:true,next_cursor:player.notification_cursor});}catch(e){return json(res,400,{ok:false,message:'bad json'});}
  }
  if(p==='/api/promo/redeem' && req.method==='POST'){
    try{const b=await body(req); const id=String(b.player_id||'').slice(0,80); const code=cleanCode(b.code); if(!id||!code) return json(res,400,{ok:false,message:'Нужны игрок и код'});
      const player=state.players[id]||{player_id:id,name:String(b.name||'ИГРОК').slice(0,20),banned:false}; if(player.banned) return json(res,403,{ok:false,message:'Аккаунт ограничен'});
      const pc=(state.promocodes||[]).find(x=>cleanCode(x.code)===code); if(!pc||!pc.active) return json(res,404,{ok:false,message:'Промокод не найден'});
      if(pc.expires && Date.parse(pc.expires)<Date.now()) return json(res,410,{ok:false,message:'Срок промокода истёк'});
      if(pc.max_uses>0 && pc.used>=pc.max_uses) return json(res,409,{ok:false,message:'Лимит активаций исчерпан'});
      player.redeemed=player.redeemed||{}; if(player.redeemed[code]) return json(res,409,{ok:false,message:'Этот промокод уже использован'});
      const reward=Math.max(0,Math.floor(Number(pc.reward||0))); pc.used=(pc.used||0)+1; player.redeemed[code]=new Date().toISOString(); state.players[id]=player; saveState(); audit('promo_redeem',{player_id:id,code,reward});
      return json(res,200,{ok:true,reward,message:`Промокод принят • +${reward} ₽`});
    }catch(e){return json(res,400,{ok:false,message:'bad json'});}
  }
  if(p==='/api/admin/login' && req.method==='POST'){
    try{const b=await body(req); if(String(b.password||'')!==ADMIN_PASSWORD) return json(res,401,{ok:false,message:'Неверный пароль'}); const t=token(); sessions.set(t,Date.now()+86400000); return json(res,200,{ok:true,token:t});}catch(e){return json(res,400,{ok:false});}
  }
  if(p.startsWith('/api/admin/')){
    if(!auth(req)) return json(res,401,{ok:false,message:'Требуется вход администратора'});
    if(p==='/api/admin/state' && req.method==='GET') return json(res,200,{ok:true,state});
    if(p==='/api/admin/state' && req.method==='POST'){
      try{const b=await body(req); if(b.settings) state.settings=normalizeSettings(b.settings); if(Array.isArray(b.promocodes)) state.promocodes=b.promocodes.slice(0,1000).map(x=>({code:cleanCode(x.code),reward:Math.max(0,Math.floor(Number(x.reward||0))),max_uses:Math.max(0,Math.floor(Number(x.max_uses||0))),used:Math.max(0,Math.floor(Number(x.used||0))),active:!!x.active,expires:String(x.expires||'')})).filter(x=>x.code); if(Array.isArray(b.news)) state.news=b.news.slice(0,500).map(x=>({id:String(x.id||crypto.randomUUID()),date:String(x.date||''),type:String(x.type||'news'),title:String(x.title||'').slice(0,120),text:String(x.text||'').slice(0,1000)})); if(Array.isArray(b.events)) state.events=b.events.slice(0,100).map(x=>({id:String(x.id||crypto.randomUUID()),name:String(x.name||''),description:String(x.description||''),end_unix:Math.floor(Number(x.end_unix||0)),bonus:Number(x.bonus||0),reward_mult:Number(x.reward_mult||1),active:!!x.active})); if(b.season && typeof b.season==='object'){const max=Math.min(100,Math.max(1,Math.floor(Number(b.season.max_level||30)))); state.season={name:String(b.season.name||'Сезон 1').slice(0,80),max_level:max,levels:Array.from({length:max},(_,i)=>{const r=(b.season.levels||[])[i]||{};return {level:i+1,type:String(r.type||'рубли').slice(0,40),reward:String(r.reward||'').slice(0,200)}})}} if(Array.isArray(b.chests)) state.chests=b.chests.slice(0,100).map(x=>({id:String(x.id||crypto.randomUUID()),name:String(x.name||'Сундук').slice(0,80),key_cost:Math.max(1,Math.floor(Number(x.key_cost||1))),rewards:String(x.rewards||'').slice(0,2000)})); saveState(); audit('admin_state_update'); return json(res,200,{ok:true,state});}catch(e){return json(res,400,{ok:false,message:'bad data'});}
    }
    if(p==='/api/admin/player' && req.method==='POST'){
      try{const b=await body(req); const id=String(b.player_id||''); if(!state.players[id]) return json(res,404,{ok:false,message:'Игрок не найден'}); const pl=state.players[id]; if(b.action==='ban') pl.banned=true; if(b.action==='unban') pl.banned=false; if(b.action==='set_coins'){const value=Math.max(0,Math.floor(Number(b.coins||0))); pl.coins=value; pl.admin_coins_override=value;} if(b.action==='set_score'){pl.score=Math.max(0,Math.floor(Number(b.score||0)));} state.players[id]=pl; saveState(); audit('admin_player',{player_id:id,action:b.action}); return json(res,200,{ok:true,player:pl});}catch(e){return json(res,400,{ok:false});}
    }
    if(p==='/api/admin/notify' && req.method==='POST'){
      try{const b=await body(req); const target=String(b.player_id||'all').slice(0,80); const n=queueNotification(target,b.title,b.message,b.kind||'general',Number(b.deliver_at||0)); return json(res,200,{ok:true,notification:n});}catch(e){return json(res,400,{ok:false,message:'bad notification'});}
    }
    if(p==='/api/admin/notifications' && req.method==='GET') return json(res,200,{ok:true,notifications:state.notifications.slice(-200).reverse()});
    return json(res,404,{ok:false,message:'Unknown admin endpoint'});
  }
  if(p==='/' || p==='/index.html') {const html=fs.readFileSync(path.join(__dirname,'public','index.html')); res.writeHead(200,{'Content-Type':'text/html; charset=utf-8'}); return res.end(html);}
  return json(res,404,{ok:false,message:'Not found'});
}

setInterval(()=>{ const now=Date.now(); for(const [t,exp] of sessions) if(exp<now) sessions.delete(t); },3600000);
http.createServer((req,res)=>handle(req,res).catch(e=>json(res,500,{ok:false,message:'server error'}))).listen(PORT,()=>console.log(`Хватайка server: http://0.0.0.0:${PORT}`));
