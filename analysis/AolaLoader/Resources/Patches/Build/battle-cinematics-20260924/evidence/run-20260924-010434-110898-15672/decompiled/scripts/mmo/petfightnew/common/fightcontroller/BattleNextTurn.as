package mmo.petfightnew.common.fightcontroller
{
   import flash.events.TimerEvent;
   import flash.utils.Timer;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.degenerator.DegeneratorPetType;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.loader.error.InspectorErrorLog;
   import mmo.loader.error.InspectorErrorWatch;
   import mmo.petfightnew.DocPetFight;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.MCPetContainer;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class BattleNextTurn implements IDispose
   {
      
      private static var _instance:BattleNextTurn;
      
      private var fightPanel:FightPanel;
      
      private var _myPetStates:Object = {};
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _mingYunPetArr:Array = [];
      
      private var _timer:Timer;
      
      public function BattleNextTurn()
      {
         super();
      }
      
      public static function get instance() : BattleNextTurn
      {
         if(_instance == null)
         {
            _instance = new BattleNextTurn();
         }
         return _instance;
      }
      
      public function init(param1:FightPanel) : void
      {
         this.fightPanel = param1;
         this._timer = new Timer(1000 * 180);
         this._timer.addEventListener(TimerEvent.TIMER,this.onTimerEvt);
      }
      
      public function battleNextTurn(param1:Object) : void
      {
         FightData.instance.myInfo.updateLockRoundAndSkillUseInfo();
         this.parseData(param1);
         this._timer.reset();
         this._timer.start();
         this.updatePetSoulNumAndState();
         this.checkPlayMovie();
      }
      
      private function onTimerEvt(param1:TimerEvent) : void
      {
         var _loc2_:InspectorErrorLog = new InspectorErrorLog("回合超时了！");
         InspectorErrorWatch.instance.addErrorLog(_loc2_);
         this._timer && this._timer.stop();
      }
      
      private function parseData(param1:Object) : void
      {
         var _loc5_:* = false;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:Boolean = false;
         var _loc10_:int = 0;
         var _loc11_:Array = null;
         var _loc12_:String = null;
         var _loc13_:Array = null;
         this._myPetStates = {};
         var _loc2_:Boolean = FightController.instance.isReplay;
         var _loc3_:int = param1.tt == null ? 0 : int(param1.tt);
         FightData.instance.myInfo.extraTurn = _loc3_;
         var _loc4_:String = param1.desc;
         if(_loc4_ == null || _loc4_.length <= 0)
         {
            _loc5_ = Boolean(param1.cus);
            _loc6_ = int(param1.csn);
            _loc7_ = int(param1.cln);
            _loc8_ = 0;
            _loc9_ = Boolean(param1.be) && !_loc2_;
            _loc10_ = int(FightData.instance.myInfo.operatingPlayer.slotId);
            FightData.instance.myInfo.setPlayerOperatedState(_loc10_,!_loc9_);
            FightData.instance.myInfo.setAllows(_loc10_,_loc5_);
            FightData.instance.myInfo.setNeedOperates(_loc10_,_loc9_);
            this._myPetStates[_loc10_] = {
               "allow":_loc5_,
               "soulNum":_loc6_,
               "xinghuiSoulNum":_loc7_,
               "GQSoulNum":_loc8_,
               "needOperate":_loc9_,
               "tt":_loc3_
            };
         }
         else
         {
            _loc11_ = _loc4_.split(";");
            for each(_loc12_ in _loc11_)
            {
               _loc13_ = _loc12_.split("-");
               _loc10_ = parseInt(_loc13_[0]);
               _loc5_ = parseInt(_loc13_[1]) == 1;
               _loc6_ = parseInt(_loc13_[2]);
               _loc9_ = parseInt(_loc13_[3]) == 1 && !_loc2_;
               _loc7_ = parseInt(_loc13_[5]);
               _loc8_ = parseInt(_loc13_[6]);
               FightData.instance.myInfo.setPlayerOperatedState(_loc10_,!_loc9_);
               FightData.instance.myInfo.setAllows(_loc10_,_loc5_);
               FightData.instance.myInfo.setNeedOperates(_loc10_,_loc9_);
               this._myPetStates[_loc10_] = {
                  "allow":_loc5_,
                  "soulNum":_loc6_,
                  "needOperate":_loc9_,
                  "tt":_loc3_,
                  "xinghuiSoulNum":_loc7_,
                  "GQSoulNum":_loc8_
               };
            }
         }
         if(param1.auto)
         {
            FightController.isAutoUseSkill = param1.auto;
         }
      }
      
      private function updatePetSoulNumAndState() : void
      {
         var _loc3_:PlayerBattleInfo = null;
         var _loc4_:PlayerBattleInfo = null;
         var _loc5_:PetBriefInfo = null;
         var _loc6_:PetBriefInfo = null;
         var _loc1_:Array = FightData.instance.myInfo.playerInfos;
         var _loc2_:Object = null;
         for each(_loc3_ in _loc1_)
         {
            _loc5_ = _loc3_.myPets[0];
            _loc2_ = this._myPetStates[_loc3_.slotId];
            if(_loc2_ != null)
            {
               if(_loc5_ != null)
               {
                  _loc5_.curSoulNum = _loc2_["soulNum"];
                  _loc5_.curXinghuiSoulNum = _loc2_["xinghuiSoulNum"];
                  _loc5_.curGQSoulNum = _loc2_["GQSoulNum"];
               }
            }
         }
         for each(_loc4_ in FightData.instance.playerInfo)
         {
            _loc6_ = _loc4_.myPets[0];
            if(_loc6_ != null)
            {
               (this.fightPanel.petMCList[_loc4_.locaId] as MCPetContainer).setPetColorTransform();
            }
         }
      }
      
      private function checkPlayMovie() : void
      {
         if(DocPetFight.skipBattlePresentation)
         {
            this.handle();
            return;
         }
         var _loc1_:PlayerBattleInfo = null;
         var _loc2_:int = 0;
         var _loc3_:PetBriefInfo = null;
         var _loc4_:PMData = null;
         var _loc5_:SkillInfo = null;
         if(FightData.instance.isLowQuality)
         {
            this.checkAutoTalk();
         }
         else if(FightData.instance.myInfo.extraTurn == 1)
         {
            for each(_loc1_ in FightData.instance.playerInfo)
            {
               _loc2_ = int(_loc1_.myPets[0].raceId);
               _loc3_ = _loc1_.myPets[0];
               _loc4_ = this._pmSvr.customData.pmDataMap.getPM(_loc2_);
               if(_loc4_.getDegeneratorType() == DegeneratorPetType.MINGYUN)
               {
                  for each(_loc5_ in _loc3_.skills)
                  {
                     if(this._pmSvr.customData.pmSkillMap.getSkill(_loc5_.id).getSkillType() == PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_ZHU_PASSIVE)
                     {
                        this._mingYunPetArr.push(_loc2_);
                        break;
                     }
                  }
               }
            }
            this.showDegeneratorMovie();
         }
         else
         {
            this.checkAutoTalk();
         }
      }
      
      private function showDegeneratorMovie() : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function checkAutoTalk() : void
      {
         PMAutoTalk.checkTalk(this.fightPanel,function():void
         {
            BossMovieHelper.instance.checkMovieAndPlay(handle);
         });
      }
      
      private function handle() : void
      {
         if(FightData.instance.myInfo.havePlayerCanOperate())
         {
            FightController.instance.dispatchEvent(new PetFightEvent(PetFightEvent.NEXT_TURN,{}));
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.FightCountPayerCanSelect,{}));
         }
         if(this._myPetStates[FightData.instance.getSlotId(0)])
         {
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.NEXT_TURN,{
               "turnCount":FightController.instance.turnCount,
               "myPetState":this._myPetStates[FightData.instance.getSlotId(0)]
            }));
         }
         else
         {
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.NEXT_TURN,{"turnCount":FightController.instance.turnCount}));
         }
         if(FightController.instance.isReplay)
         {
            FightController.instance.handle();
            return;
         }
         this.setReady();
         this.addStopMovie();
         FightController.instance.handle();
      }
      
      private function setReady() : void
      {
         this.fightPanel.setReady();
      }
      
      private function addStopMovie() : void
      {
         var _loc3_:PlayerBattleInfo = null;
         var _loc4_:PlayerBattleInfo = null;
         var _loc5_:Object = null;
         var _loc6_:PetBriefInfo = null;
         var _loc1_:Array = FightData.instance.myInfo.playerInfos;
         var _loc2_:Object = null;
         for each(_loc3_ in _loc1_)
         {
            _loc2_ = this._myPetStates[_loc3_.slotId];
            if(_loc2_ == null || _loc2_.allow && _loc2_.tt == 0)
            {
               this.fightPanel.removeStopMovie(_loc3_.locaId);
            }
            else if(Boolean(_loc2_.allow) && _loc2_.tt == 1)
            {
               this.fightPanel.addStopMovie(_loc3_.locaId,_loc2_.tt + 1);
            }
            else
            {
               _loc6_ = _loc3_.myPets[0];
               if(_loc6_ != null && _loc6_.curHp > 0)
               {
                  this.fightPanel.addStopMovie(_loc3_.locaId,_loc2_.tt);
               }
            }
         }
         _loc4_ = FightData.instance.myInfo.operatingPlayer;
         _loc5_ = this._myPetStates[_loc4_.slotId];
         if(_loc5_ != null && _loc4_.myPets[0] != null && _loc4_.myPets[0].curHp > 0 && !_loc5_.allow && !_loc5_.needOperate && _loc5_.tt == 1)
         {
            this.fightPanel.disableClick();
         }
      }
      
      public function dispose() : void
      {
         this._timer && this._timer.removeEventListener(TimerEvent.TIMER,this.onTimerEvt);
         this._timer = null;
         this.fightPanel = null;
         _instance = null;
      }
   }
}

