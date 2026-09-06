package mmo.petfightnew.common.ui
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.text.TextField;
   import mmo.common.DateUtil;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetAssetsMap;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.fightcontroller.UseBigSkillHandler;
   import mmo.petfightnew.common.handler.PetHeadIconHandler;
   import mmo.petfightnew.common.handler.attributeicon.FightAttributeIconCacheKey;
   import mmo.petfightnew.common.handler.attributeicon.FightAttributeIconListHandler;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.panel.hp.NewHPBar;
   import mmo.petfightnew.common.panel.status.NewStatusIconList;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.actthings.helper.ActComHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol3768")]
   public class MyPetInfoPanel extends MovieClip implements IDispose
   {
      
      public var btnChangZhu:SimpleButton;
      
      public var btnDeadZoneExplore:SimpleButton;
      
      public var mcAttribute:MovieClip;
      
      public var mcBack:MovieClip;
      
      public var mcDijieshiPetIcon:MovieClip;
      
      public var mcHP:MovieClip;
      
      public var mcPetFightSpace3:MovieClip;
      
      public var mcSetUI:MovieClip;
      
      public var mcStatusList:NewStatusIconList;
      
      public var mcXiYaFightIcon:MovieClip;
      
      public var mcnooperating0:MovieClip;
      
      public var mcnooperating1:MovieClip;
      
      public var mcnooperating2:MovieClip;
      
      public var mcoperatingpeticon:MovieClip;
      
      public var txtLv:TextField;
      
      public var txtLvDes:TextField;
      
      public var txtName:TextField;
      
      private const MAX_NO_OPERATING_PET:int = 3;
      
      private const CLICK_INTERVAL_MS:int = 500;
      
      private var _pmService:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _petDataService:IPetDataService = ServicePool.instance.getService(IPetDataService);
      
      private var _gameOptionSvr:IGameOptionService = ServicePool.instance.getService(IGameOptionService);
      
      private var _fightPanel:FightPanel = null;
      
      private var _operatingPetIcon:PetHeadIconHandler = null;
      
      private var _noOperatinPetIcons:Array = [];
      
      private var _statusIconList:NewStatusIconList = null;
      
      private var _attributeIconList:FightAttributeIconListHandler;
      
      private var _hpBar:NewHPBar;
      
      private var _canOpreate:Boolean = false;
      
      private var _lastClickTime:Number = 0;
      
      private var _dijieshiPetIcon:GQDijieshiPetIcon;
      
      private var _deadZoneExploreBtn:SimpleButton;
      
      private var _petFightSpace3Mc:MovieClip;
      
      private var _xiyaFightIcon:GQXiYaFightIcon;
      
      private var _setUIMc:MovieClip;
      
      private var _changZhuBtn:SimpleButton;
      
      public function MyPetInfoPanel()
      {
         super();
         this.init();
      }
      
      public function setFightPanel(param1:FightPanel) : void
      {
         this._fightPanel = param1;
      }
      
      private function init() : void
      {
         var _loc1_:MovieClip = this.getChildByName("mcoperatingpeticon") as MovieClip;
         this._operatingPetIcon = new PetHeadIconHandler(_loc1_,1);
         this._statusIconList = this.getChildByName("mcStatusList") as NewStatusIconList;
         this._statusIconList.sortDirection = NewStatusIconList.TO_LEFT;
         var _loc2_:MovieClip = this.getChildByName("mcAttribute") as MovieClip;
         this._attributeIconList = new FightAttributeIconListHandler(_loc2_,FightAttributeIconCacheKey.SMALL);
         var _loc3_:MovieClip = this.getChildByName("mcHP") as MovieClip;
         this._hpBar = new NewHPBar(_loc3_,false,true);
         this.initNoOperationIcons();
         var _loc4_:MovieClip = this.getChildByName("mcBack") as MovieClip;
         _loc4_.gotoAndStop(this.haveNoOperatingPet(0) ? 1 : 2);
         this._dijieshiPetIcon = new GQDijieshiPetIcon(this.getChildByName("mcDijieshiPetIcon") as MovieClip);
         this._xiyaFightIcon = new GQXiYaFightIcon(this.getChildByName("mcXiYaFightIcon") as MovieClip);
         this._deadZoneExploreBtn = this.getChildByName("btnDeadZoneExplore") as SimpleButton;
         this._deadZoneExploreBtn.addEventListener(MouseEvent.CLICK,this.onClickDeadZoneExplore);
         this._deadZoneExploreBtn.visible = false;
         this._petFightSpace3Mc = this.getChildByName("mcPetFightSpace3") as MovieClip;
         this._petFightSpace3Mc.addEventListener(MouseEvent.CLICK,this.onClickPetFightSpace3);
         this._petFightSpace3Mc.visible = false;
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.NEXT_TURN,this.onNextTurn);
         this._changZhuBtn = this.getChildByName("btnChangZhu") as SimpleButton;
         this._changZhuBtn.addEventListener(MouseEvent.CLICK,this.onClickChangZhu);
         this.setChangZhuBtnTips();
         this._setUIMc = this.getChildByName("mcSetUI") as MovieClip;
         this._setUIMc.addEventListener(MouseEvent.CLICK,this.onClickSetUI);
         this.setUI();
      }
      
      private function setChangZhuBtnTips() : void
      {
         TipsManager.getInstance().replaceTips(this._changZhuBtn,FightData.instance.isChangZhuVisible ? "不显示常驻buff" : "显示常驻buff");
      }
      
      private function initNoOperationIcons() : void
      {
         var _loc2_:MovieClip = null;
         var _loc1_:int = 0;
         while(_loc1_ < this.MAX_NO_OPERATING_PET)
         {
            _loc2_ = this.getChildByName("mcnooperating" + _loc1_) as MovieClip;
            if(this.haveNoOperatingPet(_loc1_))
            {
               _loc2_.visible = false;
               _loc2_.mouseChildren = false;
               _loc2_.buttonMode = true;
               _loc2_.addEventListener(MouseEvent.CLICK,this.onClickNoOperatingPet);
               this._noOperatinPetIcons[_loc1_] = new PetHeadIconHandler(_loc2_.mcicon,0.6);
            }
            else
            {
               DisplayUtil.stopAndRemove(_loc2_);
            }
            _loc1_++;
         }
      }
      
      private function setUI() : void
      {
         var _loc4_:MovieClip = null;
         var _loc1_:Boolean = Boolean(this._gameOptionSvr.isNewFightPetInfoUI);
         ActComHelper.setVisible(this,"mcBack",!_loc1_);
         ActComHelper.setVisible(this,"mcHP",!_loc1_);
         ActComHelper.setVisible(this,"txtName",!_loc1_);
         this._statusIconList.visible = !_loc1_;
         ActComHelper.setVisible(this,"txtLv",!_loc1_);
         ActComHelper.setVisible(this,"txtLvDes",!_loc1_);
         ActComHelper.setMcFrame(this,"mcSetUI",_loc1_ ? 1 : 2);
         var _loc2_:Array = [new Point(6.25,24),new Point(-41.25,24),new Point(-88.75,24)];
         var _loc3_:int = 0;
         while(_loc3_ < this.MAX_NO_OPERATING_PET)
         {
            _loc4_ = this.getChildByName("mcnooperating" + _loc3_) as MovieClip;
            if(_loc4_)
            {
               _loc4_.x = _loc2_[_loc3_].x + (_loc1_ ? 12 : 0);
               _loc4_.y = _loc2_[_loc3_].y + (_loc1_ ? -15 : 0);
            }
            _loc3_++;
         }
      }
      
      private function onClickChangZhu(param1:MouseEvent) : void
      {
         FightData.instance.isChangZhuVisible = !FightData.instance.isChangZhuVisible;
         var _loc2_:int = 0;
         while(_loc2_ < FightData.instance.playerInfo.length)
         {
            this._fightPanel.updatePetInfoMC(FightData.instance.playerInfo[_loc2_]);
            _loc2_++;
         }
         this.setChangZhuBtnTips();
      }
      
      private function onClickSetUI(param1:MouseEvent) : void
      {
         this._gameOptionSvr.isNewFightPetInfoUI = !this._gameOptionSvr.isNewFightPetInfoUI;
         this.setUI();
      }
      
      private function onNextTurn(param1:PetFightEvent) : void
      {
         this._dijieshiPetIcon.refresh(null);
         this._xiyaFightIcon.refresh(null);
      }
      
      private function haveNoOperatingPet(param1:int) : Boolean
      {
         return param1 < FightData.instance.canControlPetNum - 1;
      }
      
      public function dispose() : void
      {
         var _loc2_:PetHeadIconHandler = null;
         var _loc3_:MovieClip = null;
         var _loc1_:int = 0;
         while(_loc1_ < this.MAX_NO_OPERATING_PET)
         {
            _loc3_ = this.getChildByName("mcnooperating" + _loc1_) as MovieClip;
            if(_loc3_ != null)
            {
               _loc3_.removeEventListener(MouseEvent.CLICK,this.onClickNoOperatingPet);
            }
            _loc1_++;
         }
         this._operatingPetIcon && this._operatingPetIcon.dispose();
         this._operatingPetIcon = null;
         for each(_loc2_ in this._noOperatinPetIcons)
         {
            _loc2_.dispose();
         }
         this._noOperatinPetIcons.length = 0;
         this._noOperatinPetIcons = null;
         this._attributeIconList && this._attributeIconList.dispose();
         this._attributeIconList = null;
         this._statusIconList && this._statusIconList.dispose();
         this._statusIconList = null;
         this._dijieshiPetIcon && this._dijieshiPetIcon.dispose();
         this._dijieshiPetIcon = null;
         this._xiyaFightIcon && this._xiyaFightIcon.dispose();
         this._xiyaFightIcon = null;
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.NEXT_TURN,this.onNextTurn);
         this._deadZoneExploreBtn.removeEventListener(MouseEvent.CLICK,this.onClickDeadZoneExplore);
         this._petFightSpace3Mc.removeEventListener(MouseEvent.CLICK,this.onClickPetFightSpace3);
         this._setUIMc.removeEventListener(MouseEvent.CLICK,this.onClickSetUI);
         this._changZhuBtn.removeEventListener(MouseEvent.CLICK,this.onClickChangZhu);
         this._deadZoneExploreBtn = null;
         this._petFightSpace3Mc = null;
         this._setUIMc = null;
         this._changZhuBtn = null;
         this._fightPanel = null;
         this._hpBar = null;
      }
      
      private function onClickDeadZoneExplore(param1:MouseEvent) : void
      {
         var _loc2_:PlayerBattleInfo = FightData.instance.myInfo.operatingPlayer;
         var _loc3_:PetBriefInfo = _loc2_.myPets[0];
         var _loc4_:int = StatusUtil.getDeadZoneExploreSkillIdByPbi(_loc3_);
         var _loc5_:int = int(this._pmService.customData.pmSkillMap.getSkill(_loc4_).getSkillType());
         UseBigSkillHandler.instance.handleUse(_loc3_,StatusUtil.getDeadZoneExploreSkillIdByPbi(_loc3_),_loc5_);
      }
      
      private function onClickPetFightSpace3(param1:MouseEvent) : void
      {
         var _loc2_:PlayerBattleInfo = null;
         var _loc3_:PetBriefInfo = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         if(param1.target.name == "btnPetFightSpace3")
         {
            _loc2_ = FightData.instance.myInfo.operatingPlayer;
            _loc3_ = _loc2_.myPets[0];
            _loc4_ = StatusUtil.getPetFightSpace3SkillIdByPbi(_loc3_);
            _loc5_ = int(this._pmService.customData.pmSkillMap.getSkill(_loc4_).getSkillType());
            UseBigSkillHandler.instance.handleUse(_loc3_,_loc4_,_loc5_);
         }
      }
      
      private function onClickNoOperatingPet(param1:MouseEvent) : void
      {
         var _loc2_:Number = Number(DateUtil.getServerTime().time);
         if(_loc2_ - this._lastClickTime < this.CLICK_INTERVAL_MS)
         {
            return;
         }
         this._lastClickTime = _loc2_;
         var _loc3_:MovieClip = param1.currentTarget as MovieClip;
         var _loc4_:int = int(Panel_Helper.getNameIndex(_loc3_.name,"mcnooperating"));
         var _loc5_:Array = FightData.instance.myInfo.getNoOperatingPlayers();
         var _loc6_:PlayerBattleInfo = _loc5_[_loc4_];
         if(_loc6_ == null)
         {
            return;
         }
         if(!FightData.instance.myInfo.haveOperateRight(_loc6_))
         {
            return;
         }
         if(_loc6_.myPets[0].curHp <= 0)
         {
            return;
         }
         if(FightData.instance.myInfo.hasOperated(_loc6_.slotId))
         {
            return;
         }
         this._fightPanel.setPlayerOperating(_loc6_.slotId);
         if(FightData.instance.myInfo.extraTurn == 1)
         {
            if(FightData.instance.myInfo.getAllows(_loc6_.slotId) && FightData.instance.myInfo.getNeedOperates(_loc6_.slotId))
            {
               this._fightPanel.enableClick();
            }
            else
            {
               this._fightPanel.disableClick(true);
            }
         }
      }
      
      public function clearStatusSmallIcon() : void
      {
         this._statusIconList.clear();
      }
      
      public function refreshStatusIconView(param1:String, param2:PlayerBattleInfo) : void
      {
         var _loc3_:Array = StatusUtil.parseStatusStr(param1);
         this._statusIconList.refresh(_loc3_,param2);
      }
      
      public function refreshOperatingPetInfoView() : void
      {
         var _loc6_:int = 0;
         var _loc7_:PMSkill = null;
         var _loc8_:String = null;
         var _loc9_:String = null;
         var _loc1_:PlayerBattleInfo = FightData.instance.myInfo.operatingPlayer;
         var _loc2_:PetBriefInfo = _loc1_.myPets[0];
         var _loc3_:TextField = this.getChildByName("txtLv") as TextField;
         _loc3_.text = _loc2_.level.toString();
         var _loc4_:TextField = this.getChildByName("txtName") as TextField;
         var _loc5_:PetBriefInfo = this._petDataService.getPetByPetId(_loc2_.id);
         if(FightData.instance.myInfo.isClientPackage && _loc5_ && !FightController.instance.isReplay && _loc2_.raceId == _loc5_.raceId)
         {
            _loc4_.text = _loc5_.nickname;
         }
         else
         {
            _loc4_.text = _loc2_.nickname;
         }
         this._attributeIconList.setAttribute(_loc2_.raceId,_loc2_);
         this._hpBar.update(_loc2_);
         this._operatingPetIcon.setIcon(PetAssetsMap.getPetFlaId(_loc2_.viewId));
         this.refreshStatusIconView(_loc2_.status,_loc1_);
         this._dijieshiPetIcon.refresh(_loc2_);
         this._xiyaFightIcon.refresh(_loc2_);
         if(StatusUtil.getIsDeadZoneExploreByPbi(_loc2_))
         {
            this._deadZoneExploreBtn.visible = true;
            _loc6_ = StatusUtil.getDeadZoneExploreSkillIdByPbi(_loc2_);
            _loc7_ = this._pmService.customData.pmSkillMap.getSkill(_loc6_);
            if(!StatusUtil.getCanUseSkillWithToteOrBuff(_loc2_,_loc6_))
            {
               ActComHelper.refreshObj(this,"btnDeadZoneExplore",true,"不可使用");
            }
            else if(StatusUtil.getDeadZoneExploreSkillCdByPbi(_loc2_) > 0)
            {
               ActComHelper.refreshObj(this,"btnDeadZoneExplore",true,StatusUtil.getDeadZoneExploreSkillCdByPbi(_loc2_) + "回合后方可使用");
            }
            else
            {
               if(this._gameOptionSvr.isGQSimpleSkillView)
               {
                  _loc8_ = _loc7_.oldEffectDesc;
               }
               else
               {
                  _loc8_ = _loc7_.clientDesc;
               }
               _loc9_ = _loc7_.newCnName + " 威力：" + this.getSkillPowerDesc(_loc7_.power);
               ActComHelper.refreshObj(this,"btnDeadZoneExplore",false);
               TipsManager.getInstance().replaceComplexTips(this._deadZoneExploreBtn,_loc9_,_loc8_);
            }
         }
         else
         {
            this._deadZoneExploreBtn.visible = false;
         }
         if(StatusUtil.getIsInPetFightSpace3ByPbi(_loc2_))
         {
            this._petFightSpace3Mc.visible = true;
            _loc6_ = StatusUtil.getPetFightSpace3SkillIdByPbi(_loc2_);
            _loc7_ = this._pmService.customData.pmSkillMap.getSkill(_loc6_);
            this._petFightSpace3Mc.gotoAndStop(_loc6_ - 400033 + 1);
            if(!StatusUtil.getCanUseSkillWithToteOrBuff(_loc2_,_loc6_))
            {
               ActComHelper.refreshObj(this,"mcPetFightSpace3",true,"不可使用");
            }
            else if(!StatusUtil.getPetFightSpace3CanUseSkillByPbi(_loc2_))
            {
               ActComHelper.refreshObj(this,"mcPetFightSpace3",true,"本场战斗次数用光");
            }
            else if(FightData.instance.myInfo.isSkillUsed(_loc5_.id,_loc6_))
            {
               ActComHelper.refreshObj(this,"mcPetFightSpace3",true,"已使用");
            }
            else
            {
               ActComHelper.refreshObj(this,"mcPetFightSpace3",false);
               if(this._gameOptionSvr.isGQSimpleSkillView)
               {
                  _loc8_ = _loc7_.oldEffectDesc;
               }
               else
               {
                  _loc8_ = _loc7_.clientDesc;
               }
               _loc9_ = _loc7_.newCnName + " 威力：" + this.getSkillPowerDesc(_loc7_.power);
               TipsManager.getInstance().replaceComplexTips(this._petFightSpace3Mc,_loc9_,_loc8_);
            }
         }
         else
         {
            this._petFightSpace3Mc.stop();
            this._petFightSpace3Mc.visible = false;
         }
      }
      
      protected function getSkillPowerDesc(param1:int) : String
      {
         if(param1 > 0)
         {
            return param1.toString();
         }
         return "未知";
      }
      
      public function refreshNoOperatingPetInfoView() : void
      {
         var _loc4_:MovieClip = null;
         var _loc5_:PlayerBattleInfo = null;
         var _loc6_:PetBriefInfo = null;
         var _loc7_:MovieClip = null;
         var _loc1_:Array = FightData.instance.myInfo.getNoOperatingPlayers();
         var _loc2_:int = FightData.instance.canControlPetNum - 1;
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_)
         {
            _loc4_ = this.getChildByName("mcnooperating" + _loc3_) as MovieClip;
            if(!_loc4_)
            {
               break;
            }
            _loc5_ = _loc1_[_loc3_];
            if(_loc5_ != null)
            {
               _loc4_.visible = true;
               _loc6_ = _loc5_.myPets[0];
               (this._noOperatinPetIcons[_loc3_] as PetHeadIconHandler).setIcon(_loc6_.viewId);
               if(_loc6_.curHp > 0)
               {
                  DisplayUtil.clearFilters(_loc4_);
               }
               else
               {
                  DisplayUtil.applyGray(_loc4_);
               }
               _loc7_ = _loc4_.mcsouls;
               _loc7_.visible = this.isLegendPet(_loc6_.raceId);
               _loc7_.gotoAndStop(_loc6_.curSoulNum);
            }
            _loc3_++;
         }
      }
      
      private function isLegendPet(param1:int) : Boolean
      {
         return this._pmService.getOperationPM(param1).pmData.isLegendPM();
      }
      
      public function get canOpreate() : Boolean
      {
         return this._canOpreate;
      }
      
      public function set canOpreate(param1:Boolean) : void
      {
         this._canOpreate = param1;
      }
   }
}

