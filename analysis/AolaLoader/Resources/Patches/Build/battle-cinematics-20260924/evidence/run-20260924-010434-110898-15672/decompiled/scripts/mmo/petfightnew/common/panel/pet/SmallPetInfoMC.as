package mmo.petfightnew.common.panel.pet
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.fight.TrainingFightTypes;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.event.FightEventDispatcher;
   import mmo.petfightnew.common.event.FightInnerEvent;
   import mmo.petfightnew.common.handler.attributeicon.FightAttributeIconCacheKey;
   import mmo.petfightnew.common.handler.attributeicon.FightAttributeIconListHandler;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.panel.hp.NewHPBar;
   import mmo.petfightnew.common.panel.status.NewStatusIconList;
   import mmo.petfightnew.common.util.StatusUtil;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1421")]
   public class SmallPetInfoMC extends PetInfoMCBase
   {
      
      public var btnSelectSkill:SimpleButton;
      
      public var mcAttribute:MovieClip;
      
      public var mcHP:MovieClip;
      
      public var mcStatusList:NewStatusIconList;
      
      public var txtHpRadio:TextField;
      
      public var txtInfo:TextField;
      
      private var _pmService:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _statusList:NewStatusIconList;
      
      private var _attributeIconList:FightAttributeIconListHandler;
      
      private var _hpBar:NewHPBar;
      
      private var _pbi:PetBriefInfo;
      
      private var _txtInfo:TextField;
      
      private var _txtHpRadio:TextField;
      
      private var _btnSelectSkill:SimpleButton;
      
      private var _player:PlayerBattleInfo;
      
      public function SmallPetInfoMC()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         this._statusList = this.getChildByName("mcStatusList") as NewStatusIconList;
         var _loc1_:MovieClip = this.getChildByName("mcAttribute") as MovieClip;
         this._attributeIconList = new FightAttributeIconListHandler(_loc1_,FightAttributeIconCacheKey.SMALL);
         var _loc2_:MovieClip = this.getChildByName("mcHP") as MovieClip;
         this._hpBar = new NewHPBar(_loc2_,true);
         this._txtInfo = this.getChildByName("txtInfo") as TextField;
         this._txtInfo.mouseEnabled = false;
         this._txtHpRadio = this.getChildByName("txtHpRadio") as TextField;
         this._txtHpRadio.mouseEnabled = false;
         this._btnSelectSkill = this.getChildByName("btnSelectSkill") as SimpleButton;
         this._btnSelectSkill.visible = false;
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.Fight4v4StartSelectEvent,this.setBtnState);
         this._btnSelectSkill.addEventListener(MouseEvent.CLICK,this.onClickPet);
         this._btnSelectSkill.addEventListener(MouseEvent.ROLL_OVER,this.onOverPet);
         this._btnSelectSkill.addEventListener(MouseEvent.ROLL_OUT,this.onOutPet);
      }
      
      override public function setStatus(param1:Array, param2:PlayerBattleInfo) : void
      {
         this._statusList.refresh(param1,param2);
      }
      
      override public function setPet(param1:PlayerBattleInfo) : void
      {
         var _loc3_:int = 0;
         this._player = param1;
         var _loc2_:PetBriefInfo = param1.myPets[0];
         if(param1.lingshouRealitySlotId != -1)
         {
            _loc3_ = int(FightData.instance.getPlayerInfoBySlotId(param1.lingshouRealitySlotId).myPets[0].raceId);
         }
         else
         {
            _loc3_ = int(_loc2_.raceId);
         }
         this.refreshAttribute(_loc3_,_loc2_);
         this._pbi = _loc2_;
         this._hpBar.update(_loc2_);
         this.updateText(_loc2_,param1.locaId,param1.lingshouRealitySlotId);
         if(Boolean(_loc2_) && StatusUtil.getIsAtMiBaoStrollState(_loc2_))
         {
            this._txtHpRadio.text = _loc2_.curGQSoulNum + "";
         }
         else if(StatusUtil.getIsTouzhiHpByPbi(_loc2_))
         {
            this._txtHpRadio.text = "-" + Math.ceil(StatusUtil.getTouzhiHpByPbi(_loc2_) / _loc2_.maxHp * 100) + "%";
         }
         else
         {
            this._txtHpRadio.text = Math.ceil(_loc2_.curHp / _loc2_.maxHp * 100) + "%";
         }
      }
      
      private function refreshAttribute(param1:int, param2:PetBriefInfo) : void
      {
         this._attributeIconList.setAttribute(param1,param2);
      }
      
      private function updateText(param1:PetBriefInfo, param2:int, param3:int) : void
      {
         var _loc5_:String = null;
         var _loc6_:* = null;
         var _loc7_:PlayerBattleInfo = null;
         var _loc4_:String = "Lv";
         if((FightController.instance.trainingTowerType == TrainingFightTypes.DEFEND_TYPE || FightController.instance.trainingTowerType == TrainingFightTypes.STATUS_TYPE) && !FightData.instance.isMySide(param2))
         {
            _loc5_ = "?";
         }
         else
         {
            _loc5_ = param1.level.toString();
         }
         if(param1.raceId == 20372 || param1.raceId == 20374)
         {
            _loc5_ = "?";
         }
         if(param3 == -1)
         {
            _loc6_ = param1.name;
         }
         else
         {
            _loc7_ = FightData.instance.getPlayerInfoBySlotId(param3);
            _loc6_ = (_loc7_.myPets[0] as PetBriefInfo).name + "的魂";
         }
         this._txtInfo.htmlText = "<font color=\'#FFE841\'>" + _loc4_ + _loc5_ + "</font><font color=\'#FFFFFF\'>" + _loc6_ + "</font> ";
      }
      
      override public function dispose() : void
      {
         this._attributeIconList && this._attributeIconList.dispose();
         this._attributeIconList = null;
         this._statusList && this._statusList.dispose();
         this._statusList = null;
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.Fight4v4StartSelectEvent,this.setBtnState);
         if(this._btnSelectSkill)
         {
            this._btnSelectSkill.removeEventListener(MouseEvent.CLICK,this.onClickPet);
            this._btnSelectSkill.removeEventListener(MouseEvent.ROLL_OVER,this.onOverPet);
            this._btnSelectSkill.removeEventListener(MouseEvent.ROLL_OUT,this.onOutPet);
         }
      }
      
      private function onClickPet(param1:MouseEvent) : *
      {
         FightData.instance.targetSlot = this._player.slotId;
         FightEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.CLICK_SKILL,{"haveHit":true}));
      }
      
      private function onOverPet(param1:MouseEvent) : void
      {
         FightEventDispatcher.instance.dispatchEvent(new CommonEvent(FightInnerEvent.ON_MOUSE_OVER_PET,{"locaId":this._player.locaId}));
      }
      
      private function onOutPet(param1:MouseEvent) : void
      {
         FightEventDispatcher.instance.dispatchEvent(new CommonEvent(FightInnerEvent.ON_MOUSE_OUT_PET,{"locaId":this._player.locaId}));
      }
      
      protected function setBtnState(param1:CommonEvent) : void
      {
         var _loc2_:Boolean = Boolean(param1.params.start);
         var _loc3_:int = int(param1.params.slot);
         if(!_loc2_)
         {
            this.setIsCanSelectSkill(false);
         }
         else if(Boolean(this._pbi) && _loc3_ == this._player.slotId)
         {
            this.setIsCanSelectSkill(true);
         }
      }
      
      public function setIsCanSelectSkill(param1:Boolean) : void
      {
         if(this._btnSelectSkill)
         {
            this._btnSelectSkill.visible = param1;
         }
      }
   }
}

