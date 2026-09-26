package mmo.petfightnew.common.panel
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.pet.data.GQDiJieShiSkillParse;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.component.CachedClip;
   import mmo.petfightnew.common.constant.FightSize;
   import mmo.petfightnew.common.event.FightEventDispatcher;
   import mmo.petfightnew.common.event.FightInnerEvent;
   import mmo.petfightnew.common.handler.PetHeadIconHandler;
   import mmo.petfightnew.common.handler.attributeicon.FightAttributeIconCacheKey;
   import mmo.petfightnew.common.handler.attributeicon.FightAttributeIconListHandler;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.panel.skill.EffectIcon;
   import mmo.petfightnew.common.panel.skill.EffectIcon2v2;
   import mmo.petfightnew.common.util.PositionUtil;
   import mmo.petfightnew.common.util.StatusUtil;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol433")]
   public class PetHolder extends MovieClip
   {
      
      public var mcAttribute:MovieClip;
      
      public var mcBackGround:MovieClip;
      
      public var mcDijieshiProcess:MovieClip;
      
      public var mcHPBar:MovieClip;
      
      public var mcLock:MovieClip;
      
      public var mcMouseResponder:MovieClip;
      
      public var mcPetIcon:MovieClip;
      
      public var mcState:MovieClip;
      
      public var txtHP:TextField;
      
      public var txtLevel:TextField;
      
      public var txtName:TextField;
      
      private var _petSkillMesSvr:IPetSkillMesService = ServicePool.instance.getService(IPetSkillMesService);
      
      private var petInfo:PetBriefInfo;
      
      private var _petSkillTips:PetSkillTips;
      
      private var canSelect:Boolean = false;
      
      private var _mcMouseResponder:Sprite;
      
      private var _mcEffectIcon:CachedClip = null;
      
      private var _mc2v2EffectIcons:Array = [];
      
      private var _mcBackGround:CachedClip;
      
      private var _mcState:CachedClip;
      
      private var _petHead:PetHeadIconHandler;
      
      private var _attributeIcon:FightAttributeIconListHandler;
      
      private var _txtName:TextField;
      
      private var _txtLevel:TextField;
      
      private var _txtHP:TextField;
      
      private var _mcHPBar:MovieClip;
      
      private var _mcLock:MovieClip;
      
      private var _dijieshiProcessMc:MovieClip;
      
      public function PetHolder()
      {
         super();
         this.init();
      }
      
      public function setPet(param1:PetBriefInfo) : void
      {
         this.visible = true;
         this.petInfo = param1;
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc3_:PMData = _loc2_.getOperationPM(param1.raceId).pmData;
         this.updateInfo();
         this._attributeIcon.setAttribute(param1.raceId,param1);
         this._petHead.setIcon(this.petInfo.viewId);
         this.updateGuideView();
         this.updateEffectIcon();
         this.updatePetSkillTips();
         this.updateLockState();
         this.updataDijieshiProcess(_loc3_);
      }
      
      public function setEmpty() : void
      {
         this.visible = false;
      }
      
      private function updataDijieshiProcess(param1:PMData) : void
      {
         if(param1 && this.petInfo && this.petInfo.status && Boolean(GQPetType.isDiJieShi(param1.getGQType())))
         {
            this._dijieshiProcessMc.visible = true;
            this._dijieshiProcessMc.gotoAndStop(Math.floor(GQDiJieShiSkillParse.getEnergyValue(this.petInfo) * 4 / GQPetType.getDijieshiMaxEnergy()) + 1);
            TipsManager.getInstance().replaceTips(this._dijieshiProcessMc,"当前域界能量" + GQDiJieShiSkillParse.getEnergyValue(this.petInfo) + "/" + GQPetType.getDijieshiMaxEnergy());
         }
         else
         {
            this._dijieshiProcessMc.visible = false;
            this._dijieshiProcessMc.stop();
         }
      }
      
      private function updateLockState() : void
      {
         this._mcLock.visible = this.petInfo.lockRound > 0;
         if(this.petInfo.lockRound > 0)
         {
            TipsManager.getInstance().replaceTips(this._mcLock,"当前亚比受封锁效果无法切换，剩余回合：" + this.petInfo.lockRound);
         }
      }
      
      private function updatePetSkillTips() : void
      {
         if(this._petSkillTips)
         {
            this._petSkillTips.update(this.petInfo);
         }
      }
      
      private function initListener() : void
      {
         this._mcMouseResponder = this.getChildByName("mcMouseResponder") as MovieClip;
         this._mcMouseResponder.addEventListener(MouseEvent.CLICK,this.onClick);
         this._mcMouseResponder.addEventListener(MouseEvent.MOUSE_OVER,this.mouseOver);
         this._mcMouseResponder.addEventListener(MouseEvent.MOUSE_OUT,this.mouseOut);
         FightEventDispatcher.instance.addEventListener(FightInnerEvent.SELECT_SWITCHING_PET,this.onClickPetListener);
      }
      
      private function mouseOver(param1:MouseEvent) : void
      {
         if(this.canSelect)
         {
            this._mcBackGround.gotoAndStop(2);
         }
         if(this._petSkillTips == null)
         {
            this._petSkillTips = new PetSkillTips();
            this._petSkillTips.x = this.x - 148.75;
            this._petSkillTips.y = this.y - 81.1;
            this._petSkillTips.update(this.petInfo);
         }
         if(!this.contains(this._petSkillTips))
         {
            this.parent.addChild(this._petSkillTips);
         }
         if(FightData.instance.fightSize == FightSize.TWO_VS_TWO)
         {
            this.update2V2EffectIcon();
         }
      }
      
      private function mouseOut(param1:MouseEvent) : void
      {
         var _loc2_:CachedClip = null;
         if(this.canSelect)
         {
            this._mcBackGround.gotoAndStop(1);
         }
         for each(_loc2_ in this._mc2v2EffectIcons)
         {
            DisplayUtil.stopAndRemove(_loc2_);
         }
         DisplayUtil.stopAndRemove(this._petSkillTips);
      }
      
      private function init() : void
      {
         var _loc1_:MovieClip = this.getChildByName("mcBackGround") as MovieClip;
         this._mcBackGround = new CachedClip(_loc1_);
         var _loc2_:MovieClip = this.getChildByName("mcState") as MovieClip;
         this._mcState = new CachedClip(_loc2_);
         this._mcState.gotoAndStop(3);
         var _loc3_:Sprite = this.getChild("mcPetIcon");
         this._petHead = new PetHeadIconHandler(_loc3_,0.55);
         var _loc4_:Sprite = this.getChild("mcAttribute");
         this._attributeIcon = new FightAttributeIconListHandler(_loc4_,FightAttributeIconCacheKey.SMALL);
         this._txtName = this.getChild("txtName");
         this._txtName.mouseEnabled = false;
         this._txtLevel = this.getChild("txtLevel");
         this._txtLevel.mouseEnabled = false;
         this._txtHP = this.getChild("txtHP");
         this._txtHP.mouseEnabled = false;
         this._mcHPBar = this.getChild("mcHPBar");
         this._mcHPBar.mouseEnabled = this._mcHPBar.mouseChildren = false;
         this._mcLock = this.getChildByName("mcLock") as MovieClip;
         this._dijieshiProcessMc = this.getChildByName("mcDijieshiProcess") as MovieClip;
         this.initListener();
      }
      
      private function updateEffectIcon() : void
      {
         var _loc2_:Object = null;
         var _loc3_:Object = null;
         var _loc4_:int = 0;
         var _loc5_:MovieClip = null;
         var _loc1_:PetBriefInfo = this.getTheOnlyEnemy();
         if(_loc1_ != null)
         {
            _loc2_ = this._petSkillMesSvr.getPetMes(_loc1_.raceId);
            _loc3_ = this._petSkillMesSvr.getPetMes(this.petInfo.raceId);
            _loc4_ = this._petSkillMesSvr.compareAttributeRelation(_loc3_.attribute,_loc2_.attribute,_loc2_.attribute2) + 1;
            if(this._mcEffectIcon == null)
            {
               _loc5_ = new EffectIcon() as MovieClip;
               this._mcEffectIcon = new CachedClip(_loc5_);
               this._mcEffectIcon.x = -38;
               this._mcEffectIcon.y = 10;
               this.addChild(this._mcEffectIcon);
            }
            this._mcEffectIcon.gotoAndStop(_loc4_);
         }
      }
      
      private function getTheOnlyEnemy() : PetBriefInfo
      {
         var _loc3_:PlayerBattleInfo = null;
         var _loc1_:PetBriefInfo = null;
         var _loc2_:Array = FightData.instance.opponents;
         if(_loc2_.length > 1)
         {
            return null;
         }
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_ && _loc3_.myPets.length > 0 && (_loc3_.myPets[0] as PetBriefInfo).curHp > 0)
            {
               if(_loc1_ != null)
               {
                  return null;
               }
               _loc1_ = _loc3_.myPets[0];
            }
         }
         return _loc1_;
      }
      
      private function update2V2EffectIcon() : void
      {
         var _loc3_:PlayerBattleInfo = null;
         var _loc4_:PetBriefInfo = null;
         var _loc5_:Object = null;
         var _loc6_:Object = null;
         var _loc7_:int = 0;
         var _loc8_:MovieClip = null;
         var _loc9_:MovieClip = null;
         var _loc10_:CachedClip = null;
         var _loc11_:Point = null;
         var _loc1_:Array = FightData.instance.opponents;
         var _loc2_:int = 0;
         while(_loc2_ < _loc1_.length)
         {
            _loc3_ = _loc1_[_loc2_];
            if(_loc3_ && _loc3_.myPets.length > 0 && (_loc3_.myPets[0] as PetBriefInfo).curHp > 0)
            {
               _loc4_ = _loc3_.myPets[0];
               _loc5_ = this._petSkillMesSvr.getPetMes(_loc4_.raceId);
               _loc6_ = this._petSkillMesSvr.getPetMes(this.petInfo.raceId);
               _loc7_ = this._petSkillMesSvr.compareAttributeRelation(_loc6_.attribute,_loc5_.attribute,_loc5_.attribute2) + 1;
               if(this._mc2v2EffectIcons[_loc2_] == null)
               {
                  _loc9_ = new EffectIcon2v2() as MovieClip;
                  _loc10_ = new CachedClip(_loc9_);
                  _loc11_ = PositionUtil.getDefaultPosition(_loc3_.locaId);
                  _loc10_.x = _loc11_.x + 100;
                  _loc10_.y = _loc11_.y;
                  this._mc2v2EffectIcons[_loc2_] = _loc10_;
               }
               FightController.instance.fightPanel.layerPetUp.addChild(this._mc2v2EffectIcons[_loc2_]);
               this._mc2v2EffectIcons[_loc2_].gotoAndStop(_loc7_);
               _loc8_ = this._mc2v2EffectIcons[_loc2_].getChildByName("mc") as MovieClip;
               (_loc8_) && _loc8_.gotoAndPlay(1);
            }
            _loc2_++;
         }
      }
      
      private function updateInfo() : void
      {
         var _loc1_:int = 0;
         this._txtName.text = this.petInfo.nickname;
         this._txtLevel.text = this.petInfo.level.toString();
         if(StatusUtil.getIsTouzhiHpByPbi(this.petInfo))
         {
            this._txtHP.text = "-" + StatusUtil.getTouzhiHpByPbi(this.petInfo) + "/" + this.petInfo.maxHp;
            _loc1_ = this._mcHPBar.totalFrames - int(this._mcHPBar.totalFrames * (StatusUtil.getTouzhiHpByPbi(this.petInfo) / this.petInfo.maxHp));
         }
         else
         {
            this._txtHP.text = this.petInfo.curHp + "/" + this.petInfo.maxHp;
            _loc1_ = this._mcHPBar.totalFrames - int(this._mcHPBar.totalFrames * (this.petInfo.curHp / this.petInfo.maxHp));
         }
         this._mcHPBar.gotoAndStop(_loc1_);
      }
      
      private function getChild(param1:String) : *
      {
         return this.getChildByName(param1);
      }
      
      private function updateGuideView() : void
      {
         if(this._mcBackGround)
         {
            DisplayUtil.clearFilters(this._mcBackGround);
         }
         if(this.petInfo == null)
         {
            return;
         }
         if(this.petInfo.curHp <= 0)
         {
            this.setDisable();
         }
         else if(this.isPetInBattleField() || !this.isPetCanSwitchUp())
         {
            this.setClicked();
         }
         else if(this.petInfo.curHp > 0)
         {
            this.setEnable();
         }
      }
      
      private function isPetInBattleField() : Boolean
      {
         return FightData.instance.myInfo.isPetInBattleFiled(this.petInfo.id);
      }
      
      private function isPetCanSwitchUp() : Boolean
      {
         var _loc1_:Boolean = FightData.instance.myInfo.isSwitchingOnPetDying();
         if(_loc1_)
         {
            return !FightData.instance.myInfo.isPetWillSwitchUpOnDying(this.petInfo.id);
         }
         return !FightData.instance.myInfo.isPetWillSwitchUpOnTurnOperaiton(this.petInfo.id);
      }
      
      private function setClicked() : void
      {
         this.disableClick();
         this.canSelect = false;
         this._mcBackGround.gotoAndStop(3);
         this._mcState.gotoAndStop(1);
         this._petHead.isGray = false;
      }
      
      private function setDisable() : void
      {
         this.disableClick();
         this.canSelect = false;
         this._petHead.isGray = true;
         this._mcState.gotoAndStop(2);
         if(this._mcBackGround)
         {
            DisplayUtil.applyGray(this._mcBackGround);
         }
      }
      
      private function onClickPetListener(param1:PetFightEvent) : void
      {
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent(PetFightEvent.CLICK_SWITCH_PET_HEAD,{}));
         this.updateGuideView();
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         if(!this.canSelect)
         {
            return;
         }
         if(!FightController.instance.canSwitch)
         {
            NewDialog.showFailMessage("该场战斗不能切换宠物！");
            return;
         }
         if(this.petInfo.lockRound > 0)
         {
            return;
         }
         var _loc2_:PlayerBattleInfo = FightData.instance.myInfo.operatingPlayer;
         FightController.instance.switchPM(this.petInfo.id,_loc2_.slotId);
         this.mouseOut(null);
         FightEventDispatcher.instance.dispatchEvent(new PetFightEvent(FightInnerEvent.SELECT_SWITCHING_PET,{"pi":this.petInfo.id}));
      }
      
      public function dispose() : void
      {
         var _loc1_:CachedClip = null;
         FightEventDispatcher.instance.removeEventListener(FightInnerEvent.SELECT_SWITCHING_PET,this.onClickPetListener);
         this._mcMouseResponder.removeEventListener(MouseEvent.MOUSE_OVER,this.mouseOver);
         this._mcMouseResponder.removeEventListener(MouseEvent.MOUSE_OUT,this.mouseOut);
         this._mcMouseResponder.removeEventListener(MouseEvent.CLICK,this.onClick);
         if(this._mcEffectIcon)
         {
            this._mcEffectIcon.dispose();
         }
         for each(_loc1_ in this._mc2v2EffectIcons)
         {
            DisplayUtil.stopAndRemove(_loc1_);
            _loc1_.dispose();
         }
         this._mc2v2EffectIcons.length = 0;
         this._attributeIcon.dispose();
         this._petHead.dispose();
         this._mcState.dispose();
         this._mcBackGround.dispose();
      }
      
      private function disableClick() : void
      {
         this._mcMouseResponder.buttonMode = false;
      }
      
      private function enableClick() : void
      {
         this._mcMouseResponder.buttonMode = true;
      }
      
      private function setEnable() : void
      {
         this.canSelect = true;
         this._petHead.isGray = false;
         this._mcBackGround.gotoAndStop(1);
         this._mcState.gotoAndStop(3);
         this.enableClick();
      }
   }
}

