package mmo.petfightnew.common.fightcontroller
{
   import flash.display.MovieClip;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.SimpleCustomLoader;
   import mmo.loader.common.datastructures.ResourceObject;
   import mmo.loader.scheduler.ResDomain;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.bossmovie.BossMovieConfig;
   import mmo.petfightnew.common.manager.FightMovieManager;
   
   public class BossMovieHelper
   {
      
      private static var _instance:BossMovieHelper;
      
      private var vsLastHp:Array = [];
      
      private var vsHalfHpMcs:Object = {};
      
      private var vsQuarterHpMcs:Object = {};
      
      private var vsDieMcs:Object = {};
      
      private var myQuarterHpMcs:Object = {};
      
      private var allMcs:Array = [];
      
      private var fightPanel:FightPanel;
      
      public function BossMovieHelper()
      {
         super();
      }
      
      public static function get instance() : BossMovieHelper
      {
         if(_instance == null)
         {
            _instance = new BossMovieHelper();
         }
         return _instance;
      }
      
      public function dispose() : void
      {
         this.fightPanel = null;
         _instance = null;
      }
      
      public function init(param1:FightPanel) : void
      {
         this.fightPanel = param1;
         this.refreshVsLastHp();
         this.initMovies();
      }
      
      public function playMCs(param1:Array, param2:Function) : void
      {
         var resList:Array = param1;
         var onEnd:Function = param2;
         var res:ResourceObject = resList.shift();
         if(res)
         {
            this.getBossMovieMc(res,function(param1:MovieClip):void
            {
               var mc:MovieClip = param1;
               FightMovieManager.instance.addMovie(mc);
               mc.addFrameScript(mc.totalFrames - 1,function():*
               {
                  FightMovieManager.instance.removeMovie(mc);
                  DisplayUtil.stopAndRemove(mc);
                  playMCs(resList,onEnd);
               });
               mc.gotoAndPlay(1);
               fightPanel.addChild(mc);
            });
         }
         else
         {
            onEnd.apply();
         }
      }
      
      private function getBossMovieMc(param1:ResourceObject, param2:Function) : void
      {
         var cls:Class = null;
         var movie:MovieClip = null;
         var res:ResourceObject = param1;
         var onGet:Function = param2;
         if(FightData.instance.applicationDomain.hasDefinition(res.clsName))
         {
            cls = FightData.instance.applicationDomain.getDefinition(res.clsName) as Class;
            movie = new cls() as MovieClip;
            onGet.apply(null,[movie]);
            return;
         }
         SimpleCustomLoader.loadSingleResource(res.resPath,res.clsName,LoadingSpriteType.DIALOG_WITHOUT_CANCLE,"下载中，请稍候……",function(param1:MovieClip, param2:ApplicationDomain):void
         {
            onGet.apply(null,[param1]);
         },null,null,null,new ResDomain(FightData.instance.applicationDomain));
      }
      
      public function checkMovieAndPlay(param1:Function) : void
      {
         var onEnd:Function = param1;
         this.initMovies();
         if(!this.checkVsDie())
         {
            if(!this.checkVsQuarter())
            {
               this.checkVsHalf();
            }
         }
         this.checkMyQuarter();
         this.playMCs(this.allMcs,function():*
         {
            refreshVsLastHp();
            onEnd.apply();
         });
      }
      
      private function initMovies() : void
      {
         var _loc2_:PlayerBattleInfo = null;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:ResourceObject = null;
         var _loc1_:Array = [];
         for each(_loc2_ in FightData.instance.playerInfo)
         {
            _loc4_ = int(_loc2_.myPets[0].raceId);
            if(_loc1_.indexOf(_loc4_) == -1)
            {
               _loc1_.push(_loc4_);
            }
         }
         this.vsHalfHpMcs = {};
         this.vsQuarterHpMcs = {};
         this.myQuarterHpMcs = {};
         this.vsDieMcs = {};
         for each(_loc3_ in _loc1_)
         {
            _loc5_ = BossMovieConfig.getBossMcRes(_loc3_,BossMovieConfig.HALF_HP);
            if(_loc5_)
            {
               this.vsHalfHpMcs[_loc3_] = _loc5_;
            }
            _loc5_ = BossMovieConfig.getBossMcRes(_loc3_,BossMovieConfig.QUARTER_HP);
            if(_loc5_)
            {
               this.vsQuarterHpMcs[_loc3_] = _loc5_;
            }
            _loc5_ = BossMovieConfig.getBossMcRes(_loc3_,BossMovieConfig.MY_QUARTER_HP);
            if(_loc5_)
            {
               this.myQuarterHpMcs[_loc3_] = _loc5_;
            }
            _loc5_ = BossMovieConfig.getBossMcRes(_loc3_,BossMovieConfig.DIE);
            if(_loc5_)
            {
               this.vsDieMcs[_loc3_] = _loc5_;
            }
         }
      }
      
      private function checkVsHalf() : Boolean
      {
         var condition:Function = function(param1:int):Number
         {
            return param1 / 2;
         };
         var len:int = int(this.allMcs.length);
         this.allMcs = this.allMcs.concat(this.getMCs(condition,this.vsHalfHpMcs));
         if(this.allMcs.length - len > 0)
         {
            return true;
         }
         return false;
      }
      
      private function checkVsQuarter() : Boolean
      {
         var condition:Function = function(param1:int):Number
         {
            return param1 / 4;
         };
         var len:int = int(this.allMcs.length);
         this.allMcs = this.allMcs.concat(this.getMCs(condition,this.vsQuarterHpMcs));
         if(this.allMcs.length - len > 0)
         {
            return true;
         }
         return false;
      }
      
      private function checkMyQuarter() : Boolean
      {
         var condition:Function = function(param1:int):Number
         {
            return param1 / 4;
         };
         var len:int = int(this.allMcs.length);
         this.allMcs = this.allMcs.concat(this.getMCs(condition,this.myQuarterHpMcs));
         if(this.allMcs.length - len > 0)
         {
            return true;
         }
         return false;
      }
      
      private function checkVsDie() : Boolean
      {
         var condition:Function = function(param1:int):Number
         {
            return 0;
         };
         var len:int = int(this.allMcs.length);
         this.allMcs = this.allMcs.concat(this.getMCs(condition,this.vsDieMcs));
         if(this.allMcs.length - len > 0)
         {
            return true;
         }
         return false;
      }
      
      private function getMCs(param1:Function, param2:Object) : Array
      {
         var _loc4_:PlayerBattleInfo = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:ResourceObject = null;
         var _loc10_:int = 0;
         var _loc3_:Array = [];
         for each(_loc4_ in FightData.instance.playerInfo)
         {
            _loc5_ = int(_loc4_.myPets[0].raceId);
            _loc6_ = int(_loc4_.myPets[0].curHp);
            _loc7_ = int(_loc4_.myPets[0].maxHp);
            _loc8_ = int(this.vsLastHp[_loc4_.locaId]);
            _loc9_ = param2[_loc5_];
            _loc10_ = int(param1.apply(null,[_loc7_]));
            if(_loc9_ && _loc8_ > _loc10_ && _loc6_ <= _loc10_)
            {
               _loc3_.push(_loc9_);
            }
         }
         return _loc3_;
      }
      
      private function refreshVsLastHp() : void
      {
         var _loc1_:PlayerBattleInfo = null;
         for each(_loc1_ in FightData.instance.playerInfo)
         {
            if(!FightData.instance.isMySide(_loc1_.locaId))
            {
               if(FightData.instance.playerInfo[_loc1_.locaId] != null)
               {
                  if(FightData.instance.playerInfo[_loc1_.locaId].myPets[0] != null)
                  {
                     this.vsLastHp[_loc1_.locaId] = FightData.instance.playerInfo[_loc1_.locaId].myPets[0].curHp;
                  }
               }
            }
         }
      }
   }
}

