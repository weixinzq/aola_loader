package mmo.petfightnew.common.fightcontroller
{
   import flash.geom.Point;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.petfightnew.DocPetFight;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.MCPetContainer;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.util.BSUtil;
   import mmo.petfightnew.common.util.PositionUtil;
   
   public class SwitchPm implements IDispose
   {
      
      private static var _instance:SwitchPm;
      
      private var fightPanel:FightPanel;
      
      private var _switchPlayerInfo:PlayerBattleInfo = null;
      
      private var curPet:PetBriefInfo;
      
      private var bs:String;
      
      private var _bus:Array = [];
      
      private var _params:Object = {};
      
      private var _skillWindWordList:Array = null;
      
      public function SwitchPm()
      {
         super();
      }
      
      public static function get instance() : SwitchPm
      {
         if(_instance == null)
         {
            _instance = new SwitchPm();
         }
         return _instance;
      }
      
      public function init(param1:FightPanel) : void
      {
         this.fightPanel = param1;
      }
      
      public function switchPm(param1:PlayerBattleInfo, param2:Object) : void
      {
         var _loc8_:PetBriefInfo = null;
         var _loc9_:Object = null;
         var _loc10_:PlayerBattleInfo = null;
         var _loc11_:PlayerBattleInfo = null;
         var _loc12_:String = null;
         var _loc13_:String = null;
         var _loc14_:Array = null;
         var _loc15_:Object = null;
         var _loc16_:Object = null;
         this.bs = BSUtil.parseBS(param2.bs);
         this._bus = BSUtil.parseBackGroundUp(param2.bs);
         this._params = param2;
         this.fightPanel.canStart = true;
         this.fightPanel.whoSwitch = 1;
         var _loc3_:int = int(param1.slotId);
         this._switchPlayerInfo = param1;
         param1 = FightData.instance.setLocaId(param1);
         if(param1.locaId == 0)
         {
            this.fightPanel.removeStopMovie(param1.locaId);
         }
         var _loc4_:PlayerBattleInfo = FightData.instance.playerInfo[_loc3_] as PlayerBattleInfo;
         var _loc5_:PetBriefInfo = _loc4_.myPets[0];
         var _loc6_:int = int(_loc5_.curHp);
         this.curPet = param1.myPets[0] as PetBriefInfo;
         var _loc7_:PetBriefInfo = param2.oldPMInfo as PetBriefInfo;
         if(FightData.instance.myInfo.isClientPackage && param1.PMMasterId == FightData.instance.myInfo.PMMasterId && !FightController.instance.isReplay)
         {
            this.updatePackagePetInfo(_loc7_);
         }
         _loc5_.updateInfo(_loc7_);
         if(_loc4_.myPets.length == 1)
         {
            _loc5_.updateInfo(this.curPet);
            _loc5_.becomeNormalView();
         }
         else
         {
            for each(_loc8_ in _loc4_.myPets)
            {
               if(_loc8_.id == this.curPet.id)
               {
                  _loc8_.updateInfo(this.curPet);
                  _loc8_.becomeNormalView();
                  _loc4_.myPets.splice(_loc4_.myPets.indexOf(_loc8_),1);
                  _loc4_.myPets.splice(0,0,_loc8_);
                  break;
               }
            }
         }
         if(!FightData.instance.myInfo.isClientPackage && param1.PMMasterId == FightData.instance.myInfo.PMMasterId && !FightController.instance.isReplay)
         {
            this.swapPet();
         }
         this._skillWindWordList = null;
         if(param2.pmmList != null)
         {
            FightController.instance.pmmStatuses = [];
            for each(_loc9_ in param2.pmmList)
            {
               _loc10_ = new PlayerBattleInfo();
               _loc10_.parseInfo(_loc9_);
               _loc10_ = FightData.instance.setLocaId(_loc10_);
               _loc11_ = FightData.instance.playerInfo[_loc10_.slotId];
               if(_loc11_ != null)
               {
                  _loc11_.updateIdentityInfo(_loc9_);
                  (_loc11_.myPets[0] as PetBriefInfo).updateInfo(_loc10_.myPets[0]);
                  if(param1.locaId != _loc11_.locaId)
                  {
                     this.fightPanel.updatePetInfoMC(_loc11_);
                  }
               }
               if(this._switchPlayerInfo.locaId == _loc10_.locaId)
               {
                  this._skillWindWordList = _loc9_.cbl;
               }
               _loc12_ = _loc9_.hpIncList || "";
               _loc13_ = _loc9_.shp || "";
               _loc14_ = _loc9_.cbl || [];
               _loc15_ = _loc9_.kList || {};
               _loc16_ = {
                  "hpInc":_loc9_.hpInc,
                  "player":_loc10_,
                  "srt":_loc9_.srt,
                  "aor":0,
                  "cri":_loc9_.cri,
                  "hpIncList":_loc12_.split(","),
                  "hpType":_loc9_.hpType,
                  "shp":_loc13_.split(","),
                  "skillWindWordList":_loc14_,
                  "killList":_loc15_
               };
               FightController.instance.pmmStatuses.push(_loc16_);
            }
            this.fightPanel.refreshInfos(FightController.instance.pmmStatuses);
         }
         if(_loc6_ <= 0)
         {
            this.onSwitchEnd(param1.locaId);
         }
         else
         {
            this.showSwitchMc(param1.locaId);
         }
         if(param1.PMMasterId == FightData.instance.myInfo.PMMasterId)
         {
            this.fightPanel.clearMyPetInfo();
         }
         FightData.instance.checkCatchable();
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.SWITCH_PM,{}));
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.FightAddPlayer,{
            "raceId":this.curPet.raceId,
            "locaId":param1.locaId
         }));
      }
      
      private function updatePackagePetInfo(param1:PetBriefInfo) : void
      {
         var _loc4_:PetBriefInfo = null;
         if(!FightData.instance.myInfo.isClientPackage || FightController.instance.isReplay)
         {
            return;
         }
         var _loc2_:IPetDataService = ServicePool.instance.getService(IPetDataService);
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.getMyPets().length)
         {
            _loc4_ = _loc2_.getMyPets()[_loc3_] as PetBriefInfo;
            if(_loc4_.id == param1.id)
            {
               _loc4_.updateInfo(param1);
            }
            _loc3_++;
         }
      }
      
      private function swapPet() : void
      {
         var _loc5_:PetBriefInfo = null;
         var _loc1_:PlayerBattleInfo = FightData.instance.myInfo.getMyPlayerInfoByLocalId(this._switchPlayerInfo.locaId);
         var _loc2_:PetBriefInfo = _loc1_.myPets[0] as PetBriefInfo;
         var _loc3_:Array = _loc1_.myPets;
         var _loc4_:int = 1;
         while(_loc4_ < _loc3_.length)
         {
            _loc5_ = _loc3_[_loc4_] as PetBriefInfo;
            if(_loc5_.id == this.curPet.id)
            {
               _loc5_.updateInfo(_loc2_);
               _loc5_.becomeNormalView();
               break;
            }
            _loc4_++;
         }
         _loc2_.updateInfo(this.curPet);
      }
      
      private function showSwitchMc(param1:int) : void
      {
         if(DocPetFight.skipBattlePresentation)
         {
            this.onSwitchEnd(param1);
            return;
         }
         var _loc2_:MCPetContainer = this.fightPanel.petMCList[param1];
         if(_loc2_)
         {
            _loc2_.showSwitchEffect(this.onSwitchEnd);
         }
      }
      
      private function onSwitchEnd(param1:int) : void
      {
         this.switchPet(param1);
         this.changeBS();
      }
      
      private function switchPet(param1:int) : void
      {
         var _loc2_:Boolean = false;
         --this.fightPanel.petLoadeNum;
         if(FightData.instance.isMySide(param1))
         {
            _loc2_ = false;
            if(param1 == FightData.instance.myInfo.operatingPlayer.locaId)
            {
               this.switchSkill();
            }
         }
         else
         {
            _loc2_ = true;
         }
         var _loc3_:int = MCPetContainer(this.fightPanel.petMCList[param1]).parent.getChildIndex(this.fightPanel.petMCList[param1]);
         var _loc4_:MCPetContainer = this.fightPanel.petMCList[param1];
         _loc4_.dispose();
         DisplayUtil.stopAndRemove(_loc4_);
         this.fightPanel.petMCList[param1] = new MCPetContainer(this.curPet,_loc2_,param1,this.fightPanel.layerEffect);
         var _loc5_:Point = PositionUtil.getDefaultPosition(param1);
         this.fightPanel.petMCList[param1].x = _loc5_.x;
         this.fightPanel.petMCList[param1].y = _loc5_.y;
         this.fightPanel.petMCList[param1].addEventListener(PetFightEvent.GOT_PET,this.onGotPet);
         this.fightPanel.petMCList[param1].startLoad();
         this.fightPanel.layerPet.addChildAt(this.fightPanel.petMCList[param1],_loc3_);
      }
      
      private function onGotPet(param1:PetFightEvent) : void
      {
         MCPetContainer(param1.currentTarget).removeEventListener(PetFightEvent.GOT_PET,this.onGotPet);
         if(param1.params.locaId == FightData.instance.myInfo.operatingPlayer.locaId)
         {
            this.fightPanel.setFightClicked();
         }
         this.fightPanel.onGotPet(param1);
         this.fightPanel.addEffectContainer(this._switchPlayerInfo,this._skillWindWordList);
      }
      
      private function switchSkill() : void
      {
         this.fightPanel.switchSkill();
      }
      
      private function changeBS() : void
      {
         this.fightPanel.setBS(this.bs);
         this.fightPanel.setBackGroundUp(this._bus);
         this.fightPanel.setPetUp(this._params);
      }
      
      public function dispose() : void
      {
         var _loc1_:PlayerBattleInfo = null;
         for each(_loc1_ in FightData.instance.playerInfo)
         {
            this.fightPanel.petMCList[_loc1_.locaId].removeEventListener(PetFightEvent.GOT_PET,this.onGotPet);
         }
         this.fightPanel = null;
         _instance = null;
      }
   }
}

