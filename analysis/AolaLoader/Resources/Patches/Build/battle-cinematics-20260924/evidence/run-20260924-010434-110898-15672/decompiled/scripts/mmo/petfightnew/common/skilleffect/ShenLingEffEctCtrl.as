package mmo.petfightnew.common.skilleffect
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.geom.Point;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.shareobject.LocalStore;
   import mmo.common.user.UserInfo;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.data.XingHuiShenLingSkillParser;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.util.PositionUtil;
   
   public class ShenLingEffEctCtrl
   {
      
      private static const URL_AtAll:String = "xinghuipet/shenling/effect/xinghuishenlingatallmv";
      
      private static const CLS_AtAll:String = "mmo.xinghuipet.shenling.XingHuiShenLingAtAllMv";
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _raceId:int;
      
      private var _pbi:PetBriefInfo;
      
      private var _locaId:int;
      
      private var _face:int;
      
      private var key:String = "";
      
      private var URL_level:String = "xinghuipet/shenling/effect/xinghuishenlinglevelmv";
      
      private var CLS_level_UP:String = "mmo.xinghuipet.shenling.XingHuiShenLingLevelMv_Up";
      
      private var CLS_level_DOWN:String = "mmo.xinghuipet.shenling.XingHuiShenLingLevelMv_Down";
      
      private var maxLevel:int = 3;
      
      public function ShenLingEffEctCtrl(param1:PetBriefInfo, param2:int, param3:Boolean)
      {
         super();
         var _loc4_:IGameOptionService = ServicePool.instance.getService(IGameOptionService);
         if(LocalStore.getValue(XinghuiPetType.isCloseShenLingMvkey,UserInfo.userName))
         {
            return;
         }
         this._pbi = param1;
         this._raceId = this._pbi.raceId;
         this._locaId = param2;
         this._face = param3 ? 1 : 0;
         this.key = "xinghuishenlingmaxleveleffect_" + this._locaId + "_" + this._face;
         var _loc5_:PMData = this._pmSvr.getOperationPM(this._raceId).pmData;
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.NEXT_TURN,this.onNextTurn);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.SHEN_LING_LEVEL_CHANGE,this.onChangeHandle);
         var _loc6_:XingHuiShenLingSkillParser = this._pbi.getXingHuiShenLingSkillParser();
         this.threeLevelEffect(_loc6_.level);
      }
      
      public function dispose() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.NEXT_TURN,this.onNextTurn);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.SHEN_LING_LEVEL_CHANGE,this.onChangeHandle);
         var _loc1_:DisplayObject = FightController.instance.fightPanel.layerPet.getChildByName(this.key);
         DisplayUtil.stopAndRemove(_loc1_);
      }
      
      private function onChangeHandle(param1:PetFightEvent) : void
      {
         var _loc4_:String = null;
         var _loc2_:int = int(param1.params.pid);
         var _loc3_:int = int(param1.params.locaId);
         if(!this._pbi || this._pbi.id != _loc2_ || this._locaId != _loc3_)
         {
            return;
         }
         if(param1.params.isUp)
         {
            _loc4_ = this.CLS_level_UP;
         }
         else
         {
            _loc4_ = this.CLS_level_DOWN;
         }
         var _loc5_:Point = PositionUtil.getDefaultPosition(this._locaId);
         var _loc6_:Object = XinghuiPetType.getShenLingGuard_Object(this._raceId);
         var _loc7_:String = this.URL_level;
         if(Boolean(_loc6_) && _loc6_.fightEffect > 1)
         {
            _loc7_ += "_" + _loc6_.fightEffect;
            _loc4_ += "_" + _loc6_.fightEffect;
         }
         this.playCommonEffect(_loc7_,_loc4_,_loc5_);
         var _loc8_:int = int(param1.params.level);
         this.threeLevelEffect(_loc8_);
      }
      
      private function threeLevelEffect(param1:int) : void
      {
         var hasView:Boolean;
         var obj:Object;
         var url:String;
         var cls:String;
         var layer:Sprite = null;
         var pos:Point = null;
         var mc:DisplayObject = null;
         var level:int = param1;
         this.key = "xinghuishenlingmaxleveleffect_" + this._locaId + "_" + this._face;
         layer = FightController.instance.fightPanel.layerPet;
         hasView = layer.getChildByName(this.key) != null;
         if(level < this.maxLevel)
         {
            if(hasView)
            {
               mc = layer.getChildByName(this.key);
               DisplayUtil.stopAndRemove(layer.getChildByName(this.key));
            }
            return;
         }
         if(hasView)
         {
            return;
         }
         pos = PositionUtil.getDefaultPosition(this._locaId);
         obj = XinghuiPetType.getShenLingGuard_Object(this._raceId);
         url = URL_AtAll;
         cls = CLS_AtAll;
         if(Boolean(obj) && obj.fightEffect > 1)
         {
            url += "_" + obj.fightEffect;
            cls += "_" + obj.fightEffect;
         }
         ResScheduler.getRes(ResParams.createTempByDomain(url,function(param1:MovieClip, param2:ApplicationDomain):void
         {
            param1.x = pos.x;
            param1.y = pos.y;
            param1.name = key;
            layer.addChild(param1);
         },ResDomain.decorate(FightData.instance.applicationDomain),cls,ResPriority.LOW));
      }
      
      private function onNextTurn(param1:Event) : void
      {
         var _loc4_:* = false;
         if(!this._pbi)
         {
            return;
         }
         this.playDhenlingGuardMv();
         var _loc2_:XingHuiShenLingSkillParser = this._pbi.getXingHuiShenLingSkillParser();
         var _loc3_:Sprite = FightController.instance.fightPanel.layerPet;
         if(this.key != "")
         {
            _loc4_ = _loc3_.getChildByName(this.key) != null;
            if(_loc2_.level < this.maxLevel && _loc4_)
            {
               DisplayUtil.stopAndRemove(_loc3_.getChildByName(this.key));
            }
         }
      }
      
      private function playDhenlingGuardMv() : void
      {
         var _loc1_:PMData = this._pmSvr.getOperationPM(this._raceId).pmData;
         if(XinghuiPetType.isShenLingGuard(_loc1_.getXinghuiType()) == false)
         {
            return;
         }
         var _loc2_:XingHuiShenLingSkillParser = this._pbi.getXingHuiShenLingSkillParser();
         if(_loc2_.level <= 0)
         {
            return;
         }
         var _loc3_:int = _loc2_.level > 2 ? 1 : 0;
         this.showShenLingGuardMovie(this._locaId,_loc3_);
      }
      
      private function showShenLingGuardMovie(param1:int, param2:int) : void
      {
         var _loc8_:PlayerBattleInfo = null;
         var _loc9_:PlayerBattleInfo = null;
         var _loc3_:String = "xinghuipet/shenling/effect/xinghuishenlingguardmv";
         var _loc4_:String = "mmo.xinghuipet.shenling.XingHuiShenLingGuardMv_" + param2;
         var _loc5_:int = param1;
         if(param2 == 0)
         {
            _loc8_ = FightData.instance.getPlayerInfoByLocalId(param1);
            if(!_loc8_)
            {
               return;
            }
            _loc9_ = FightData.instance.getPlayerInfoByLocalId(_loc8_.maidservantMsterSlotId);
            if(!_loc9_)
            {
               return;
            }
            _loc5_ = int(_loc9_.locaId);
         }
         var _loc6_:Object = XinghuiPetType.getShenLingGuard_Object(this._raceId);
         if((Boolean(_loc6_)) && _loc6_.guradMv > 1)
         {
            _loc3_ += "_" + _loc6_.guradMv;
            _loc4_ += "_" + _loc6_.guradMv;
         }
         var _loc7_:Point = PositionUtil.getDefaultPosition(_loc5_);
         this.playCommonEffect(_loc3_,_loc4_,_loc7_);
      }
      
      private function playCommonEffect(param1:String, param2:String, param3:Point, param4:Function = null) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
   }
}

