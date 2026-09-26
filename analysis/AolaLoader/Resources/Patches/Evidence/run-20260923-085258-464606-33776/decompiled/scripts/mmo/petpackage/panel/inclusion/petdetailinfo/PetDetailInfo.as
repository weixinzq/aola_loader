package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import mmo.common.ProgressFullSprite;
   import mmo.common.shield.Shield_Helper;
   import mmo.common.textscroll.TextHorizontalScrollComponent;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.ServiceNames;
   import mmo.interfaces.material.MaterialTypes;
   import mmo.interfaces.material.pettitle.IPetTitleService;
   import mmo.interfaces.material.pettitle.PetTitleIconParam;
   import mmo.interfaces.material.pettitle.UserPetTitle;
   import mmo.interfaces.pet.data.IPetBattleEffDataService;
   import mmo.interfaces.pet.data.IPetDictionaryDataService;
   import mmo.interfaces.pet.data.PetDictionaryDataItem;
   import mmo.interfaces.pet.nickname.IPetNicknameService;
   import mmo.interfaces.pet.petdict.IPetDictPanelService;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petpackage.service.PetPackageService;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.actthings.helper.ActMaterialLoader;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2354")]
   public class PetDetailInfo extends PetDetailBase
   {
      
      private static const TIPS:String = "点击修改亚比昵称";
      
      public var btn_rename:SimpleButton;
      
      public var btn_setpettitle:SimpleButton;
      
      public var btn_show:SimpleButton;
      
      public var btnpetdict:SimpleButton;
      
      public var mc_pettitle:MovieClip;
      
      public var mcstar:MovieClip;
      
      public var txt_avoirdupois:TextField;
      
      public var txt_date:TextField;
      
      public var txt_dec:TextField;
      
      public var txt_food:TextField;
      
      public var txt_pettitle:TextField;
      
      public var txt_raceid:TextField;
      
      public var txt_racename:TextField;
      
      public var txt_stature:TextField;
      
      private var txtHeight:TextField = null;
      
      private var txtWeight:TextField = null;
      
      private var txtFood:TextField = null;
      
      private var txtDate:TextField = null;
      
      private var mcStar:MovieClip;
      
      private var txtDec:TextField = null;
      
      private var btnPetDict:SimpleButton;
      
      private var txtRaceName:TextField = null;
      
      private var btnRename:SimpleButton = null;
      
      private var txtRaceId:TextField = null;
      
      private var btnShow:SimpleButton;
      
      private var txtPetTitle:TextField = null;
      
      private var mcPetTitle:MovieClip = null;
      
      private var btnSetPetTitle:SimpleButton = null;
      
      private var ipts:IPetTitleService = ServiceContainer.getService(IPetTitleService) as IPetTitleService;
      
      public function PetDetailInfo()
      {
         super();
         this.canUpdateUI = true;
         this.initPars();
         this.initFuns();
         this.resetUI();
      }
      
      private function initPars() : void
      {
         this.mcStar = this.mcstar as MovieClip;
         this.mcStar.stop();
         this.txtRaceName = this.txt_racename as TextField;
         this.txtRaceId = this.txt_raceid as TextField;
         new TextHorizontalScrollComponent().setText(this.txtRaceName);
         new TextHorizontalScrollComponent().setText(this.txtRaceId);
         this.txtHeight = this.txt_stature as TextField;
         this.txtWeight = this.txt_avoirdupois as TextField;
         this.txtFood = this.txt_food as TextField;
         this.txtDec = this.txt_dec as TextField;
         this.txtDate = this.txt_date as TextField;
         this.btnPetDict = this.btnpetdict as SimpleButton;
         this.btnRename = this.btn_rename as SimpleButton;
         this.btnShow = this.btn_show as SimpleButton;
         this.txtPetTitle = this.txt_pettitle as TextField;
         this.mcPetTitle = this.mc_pettitle as MovieClip;
         this.btnSetPetTitle = this.btn_setpettitle as SimpleButton;
      }
      
      private function initFuns() : void
      {
         TipsManager.getInstance().addTips(this.btnRename,TIPS);
         this.btnPetDict.addEventListener(MouseEvent.CLICK,this.onClickPetDict);
         this.btnRename.addEventListener(MouseEvent.CLICK,this.onTryRename);
         this.btnShow.addEventListener(MouseEvent.CLICK,this.onClickShow);
         this.btnSetPetTitle.addEventListener(MouseEvent.CLICK,this.onSetPetTitle);
         TipsManager.getInstance().addTips(this.btnShow,"展示亚比");
      }
      
      private function disposeFuns() : void
      {
         this.btnShow.removeEventListener(MouseEvent.CLICK,this.onClickShow);
         this.btnRename.removeEventListener(MouseEvent.CLICK,this.onTryRename);
         this.btnPetDict.removeEventListener(MouseEvent.CLICK,this.onClickPetDict);
         this.btnSetPetTitle.removeEventListener(MouseEvent.CLICK,this.onSetPetTitle);
      }
      
      private function onSetPetTitle(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         if(null != pdi && this.ipts.getPetTitleByRaceId(pdi.raceId).length > 0)
         {
            Panel_Helper.loadResAndShow("activityres/activity250829/pettitle/pettitle_code","mmo.activity250829.pettitle.panel.PetTitle_SetPl",{
               "pbi":pdi,
               "callback":this.refreshPetTitle
            });
         }
      }
      
      private function onClickShow(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         if(null != pdi)
         {
            this.unfurl();
         }
      }
      
      private function unfurl() : void
      {
         ProgressFullSprite.show();
         ResScheduler.getRes(ResParams.createTemp("talk/showpettalkpanel",function(param1:*, param2:ApplicationDomain):void
         {
            ProgressFullSprite.close();
            var _loc3_:* = param2.getDefinition("mmo.showpettalk.ShowPetTalkPanel") as Class;
            var _loc4_:* = new _loc3_(pdi.id,pdi.name) as IShowPanel;
            PetPackageService.currentPanel.closePanel();
            _loc4_.showPanel();
         },""));
      }
      
      private function onTryRename(param1:MouseEvent) : void
      {
         var e:MouseEvent = param1;
         if(Shield_Helper.isShieldDate())
         {
            Shield_Helper.showShieldPanel();
            return;
         }
         if(null == this.pdi)
         {
            return;
         }
         ProgressFullSprite.lockScreen();
         ServiceContainer.instance.tryGetService(IPetNicknameService,function(param1:IPetNicknameService, param2:Object):*
         {
            ProgressFullSprite.unlockScreen();
            param1.showChangeNicknamePanel(pdi);
         });
      }
      
      private function onClickPetDict(param1:MouseEvent) : void
      {
         var _loc2_:IPetDictPanelService = null;
         param1.stopImmediatePropagation();
         if(null != this.pdi)
         {
            PetPackageService.currentPanel.closePanel();
            _loc2_ = ServiceContainer.getService(ServiceNames.PET_DICT_PANEL) as IPetDictPanelService;
            _loc2_.showPanelByRaceId(pdi.raceId);
         }
      }
      
      private function refreshPetDictButton() : void
      {
         this.btnPetDict.visible = null != this.pdi;
      }
      
      override public function dispose() : void
      {
         this.disposeFuns();
         super.dispose();
      }
      
      override protected function resetUI() : void
      {
         this.mcStar.gotoAndStop(1);
         this.txtRaceName.text = "亚比";
         this.txtRaceId.text = "亚比";
         this.txtHeight.text = "???";
         this.txtWeight.text = "???";
         this.txtFood.text = "未知";
         this.txtDec.text = "未知";
         this.txtDate.text = "????-??-??";
         this.btnPetDict.visible = false;
      }
      
      override protected function refreshUI() : void
      {
         var _loc4_:PMData = null;
         this.resetUI();
         var _loc1_:IPetDictionaryDataService = ServiceContainer.getService(IPetDictionaryDataService) as IPetDictionaryDataService;
         this.txtDate.text = "" + pdi.getDate;
         var _loc2_:PetDictionaryDataItem = _loc1_.getDataItemByRaceId(pdi.raceId);
         if(_loc2_ != null)
         {
            this.txtHeight.text = _loc2_.petHeight;
            this.txtWeight.text = _loc2_.petWieght;
            this.txtFood.text = _loc2_.petFavourite;
            this.txtDec.text = _loc2_.petIntro;
         }
         this.btnPetDict.visible = true;
         this.txtRaceName.text = pdi.nickname;
         this.txtRaceId.text = pdi.name;
         var _loc3_:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         _loc4_ = _loc3_.getOperationPM(pdi.raceId).pmData;
         var _loc5_:IPetBattleEffDataService = ServiceContainer.getService(IPetBattleEffDataService) as IPetBattleEffDataService;
         this.setMCStar();
         this.refreshPetTitle();
      }
      
      public function refreshPetTitle() : void
      {
         var _loc1_:UserPetTitle = this.ipts.getUsingUserPetTitleByRaceId(pdi.raceId);
         if(_loc1_ != null)
         {
            this.txtPetTitle.visible = false;
            this.mcPetTitle.visible = true;
            ActMaterialLoader.setView(this.mcPetTitle,MaterialTypes.PET_TITLE,_loc1_.materialId,true,null,new PetTitleIconParam(PetTitleIconParam.SIZE_BIG,9999,_loc1_));
         }
         else
         {
            this.txtPetTitle.visible = true;
            this.mcPetTitle.visible = false;
         }
         ActComHelper.refreshObj(this.btnSetPetTitle.parent,this.btnSetPetTitle.name,this.ipts.getPetTitleByRaceId(pdi.raceId).length <= 0,"该亚比暂未开放称号");
      }
      
      private function setMCStar() : void
      {
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc1_:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var _loc2_:PMData = _loc1_.customData.pmDataMap.getPM(pdi.raceId);
         var _loc3_:Number = Number(_loc2_.getAoYiFactor());
         if(_loc2_.isGQPM())
         {
            this.mcStar.gotoAndStop(16);
         }
         else if(_loc2_.isXinghuiPM())
         {
            _loc4_ = 11 + _loc2_.getXinghuiPetStarLevel();
            this.mcStar.gotoAndStop(_loc4_);
         }
         else if(_loc2_.isDegeneratorPM())
         {
            this.mcStar.gotoAndStop(11);
         }
         else if(_loc2_.isLegendPM())
         {
            this.mcStar.gotoAndStop(10);
         }
         else if(_loc2_.isMiraclePet())
         {
            this.mcStar.gotoAndStop(9);
         }
         else if(Boolean(pdi.isGetAoYiSkill) && _loc3_ != 0)
         {
            _loc5_ = _loc3_ == 0.25 ? 7 : 8;
            this.mcStar.gotoAndStop(_loc5_);
         }
         else
         {
            this.mcStar.gotoAndStop(_loc1_.getOperationPM(pdi.raceId).getPetStarCount() - 5);
         }
      }
   }
}

