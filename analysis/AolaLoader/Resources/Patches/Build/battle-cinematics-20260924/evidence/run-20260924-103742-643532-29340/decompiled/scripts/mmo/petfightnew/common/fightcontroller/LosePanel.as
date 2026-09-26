package mmo.petfightnew.common.fightcontroller
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.GlobalVariable;
   import mmo.common.ProgressFullSprite;
   import mmo.common.event.EnterFrameManager;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.MaterialTypes;
   import mmo.interfaces.pet.data.PetAssetsMap;
   import mmo.interfaces.pet.data.skin.IPetSkinDataService;
   import mmo.interfaces.pet.data.skin.PetSkinInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.FightData;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.actthings.helper.ActMaterialLoader;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol3556")]
   public class LosePanel extends MovieClip implements IShowPanel
   {
      
      private static const OTHER_FUN:Object = {};
      
      OTHER_FUN["btnzhandoujiqiao"] = {
         "url":"activityres/activity200612/fuzhushenchong/fuzhushenchong_doc",
         "cls":"mmo.activity200612.fuzhushenchong.panel.FZSC_MainPl"
      };
      OTHER_FUN["btnbianqiang"] = {
         "url":"bariconpanels/iwantchange/iwantchangepanel",
         "cls":"mmo.bariconpanels.iwantchange.IYLevelUpPanel"
      };
      OTHER_FUN["btnmorepet"] = {
         "url":"bariconpanels/hud200320/recommendpethudcode",
         "cls":"mmo.bariconpanels.hud200320.recommendpethud.panel.RPHUDPanel"
      };
      OTHER_FUN["btnSummoner"] = {
         "url":"activityres/activity250516/newzhaohuanshi/newzhaohuanshi_code",
         "cls":"mmo.activity250516.newzhaohuanshi.panel.NZHS_MainPl"
      };
      OTHER_FUN["btnYangcheng"] = {
         "url":"pet/newpetpackage",
         "cls":"mmo.petpackage.service.PetPackageService"
      };
      
      public var btnOK:SimpleButton;
      
      public var btnSummoner:SimpleButton;
      
      public var btnYangcheng:SimpleButton;
      
      public var btnbianqiang:SimpleButton;
      
      public var btnmorepet:SimpleButton;
      
      public var btnzhandoujiqiao:SimpleButton;
      
      public var mcContent:MovieClip;
      
      public var mcPet:MovieClip;
      
      public var mcPetContent:MovieClip;
      
      private var KEY_LOST_PANEL_FRAME:String = "LOSE_PANEL_FRAME_2020";
      
      private var _pmSvr:IPMService = ServiceContainer.getService(IPMService) as IPMService;
      
      private var _petSkinDataSvr:IPetSkinDataService = ServiceContainer.getService(IPetSkinDataService);
      
      private var _clickOkCallback:Function;
      
      private var _clickCloseCallback:Function;
      
      private var _clickOtherCloseCallbck:Function;
      
      private var _petSkinInfo:PetSkinInfo;
      
      public function LosePanel(param1:Function, param2:Function, param3:Function)
      {
         super();
         this._clickOkCallback = param1;
         this._clickCloseCallback = param2;
         this._clickOtherCloseCallbck = param3;
      }
      
      private function init() : void
      {
         var _loc2_:Sprite = null;
         var _loc1_:int = this.getLostPanelFrame();
         if(FightData.instance.fightEndPbi)
         {
            this._petSkinInfo = this._petSkinDataSvr.getPetSkinInfoBySkinId(PetAssetsMap.getPetFlaId(FightData.instance.fightEndPbi.viewId));
            if(Boolean(this._petSkinInfo) && Boolean(this._petSkinInfo.hasInbetweening))
            {
               this.gotoAndStop(4);
               this.initContent();
               _loc2_ = this._petSkinDataSvr.getAndShowEndFightInbetweening(PetAssetsMap.getPetFlaId(FightData.instance.fightEndPbi.viewId),false,this.onLoaded);
               if(_loc2_)
               {
                  this.addChildAt(_loc2_,0);
               }
            }
            else
            {
               this.gotoAndStop(3);
               this.initPet();
               EnterFrameManager.instance.register(this.aotoClose,null,25 * 5);
            }
         }
         else
         {
            this.gotoAndStop(_loc1_);
            EnterFrameManager.instance.register(this.aotoClose,null,25 * 5);
         }
         this.addEventListener(MouseEvent.CLICK,this.onClickMe);
         this.addEventListener(Event.REMOVED_FROM_STAGE,this.onRemoveStage);
      }
      
      private function onLoaded(param1:MovieClip) : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:MovieClip = null;
         if(Boolean(this) && Boolean(this.parent))
         {
            this.addChild(param1);
            _loc2_ = ActComHelper.getChildNode(this,"mcPetContent") as MovieClip;
            _loc2_.gotoAndPlay(1);
            _loc3_ = ActComHelper.getChildNode(this,"mcContent") as MovieClip;
            _loc3_.gotoAndPlay(1);
            EnterFrameManager.instance.register(this.aotoClose,null,25 * 5);
         }
      }
      
      private function initContent() : void
      {
         var _loc1_:MovieClip = ActComHelper.getChildNode(this,"mcPetContent") as MovieClip;
         _loc1_.gotoAndStop(1);
         var _loc2_:MovieClip = ActComHelper.getChildNode(_loc1_,"mcPet") as MovieClip;
         ActMaterialLoader.setView(_loc2_,MaterialTypes.PET,PetAssetsMap.getPetFlaId(FightData.instance.fightEndPbi.viewId));
         var _loc3_:MovieClip = ActComHelper.getChildNode(this,"mcContent") as MovieClip;
         _loc3_.gotoAndStop(1);
      }
      
      private function initPet() : void
      {
         var _loc1_:MovieClip = ActComHelper.getChildNode(this,"mcPet") as MovieClip;
         ActMaterialLoader.setView(_loc1_,MaterialTypes.PET,PetAssetsMap.getPetFlaId(FightData.instance.fightEndPbi.viewId));
      }
      
      private function aotoClose() : void
      {
         this.removeMe();
         this._clickOkCallback();
         EnterFrameManager.instance.remove(this.aotoClose);
      }
      
      private function onRemoveStage(param1:Event) : void
      {
         this.removeEventListener(MouseEvent.CLICK,this.onClickMe);
         this.removeEventListener(Event.REMOVED_FROM_STAGE,this.onRemoveStage);
         GlobalVariable.instance.remove(this.KEY_LOST_PANEL_FRAME);
         EnterFrameManager.instance.remove(this.aotoClose);
      }
      
      private function getLostPanelFrame() : int
      {
         var _loc1_:Object = GlobalVariable.instance.getVar(this.KEY_LOST_PANEL_FRAME);
         if(_loc1_ == null)
         {
            return 1;
         }
         return _loc1_.frame;
      }
      
      private function onClickMe(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.target.name;
         switch(_loc2_)
         {
            case "btnOK":
               this.removeMe();
               this._clickOkCallback();
               break;
            case "btnClose":
               this.removeMe();
               this._clickCloseCallback();
               break;
            default:
               this.tryOtherCloseFunc(param1);
         }
      }
      
      private function tryOtherCloseFunc(param1:MouseEvent) : Boolean
      {
         var _loc3_:Object = null;
         var _loc2_:String = param1.target.name;
         if(OTHER_FUN.hasOwnProperty(_loc2_))
         {
            this.removeMe();
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.LOSE_PANEL_ClOSE_NOT_OK_CLOSE,{"evt":param1}));
            this._clickOtherCloseCallbck();
            _loc3_ = OTHER_FUN[_loc2_];
            Panel_Helper.loadResAndShow(_loc3_.url,_loc3_.cls,_loc3_.data);
            return true;
         }
         return false;
      }
      
      private function removeMe() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
      
      public function showPanel() : void
      {
         var thisObj:LosePanel = null;
         var showCurrPl:Function = null;
         showCurrPl = function():void
         {
            ProgressFullSprite.unlockScreen();
            EnterFrameManager.instance.remove(showCurrPl);
            ModalDialogManager.getInstance().addModalDialog(thisObj,AlignType.NONE);
            init();
         };
         ProgressFullSprite.lockScreen();
         EnterFrameManager.instance.register(showCurrPl,null,25);
         thisObj = this;
      }
   }
}

