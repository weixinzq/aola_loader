package mmo.petfightnew.common.panel
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.framework.comm.PetClient;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.IPetDictionaryDataService;
   import mmo.interfaces.pet.data.PetCharacterMap;
   import mmo.interfaces.pet.data.PetDataServiceEvent;
   import mmo.interfaces.pet.data.PetDetailedInfo;
   import mmo.interfaces.pet.data.PetDictionaryDataItem;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.peticon.IPetIcon;
   import mmo.interfaces.pet.peticon.PetIconContainer;
   import mmo.interfaces.pet.peticon.PetIconEvent;
   import mmo.interfaces.pet.peticon.PetIconType;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.util.component.artnumber.ArtNumberManager;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1638")]
   public class CatchDonePanel extends Sprite
   {
      
      public var attack:TextField;
      
      public var btnClose:SimpleButton;
      
      public var btnOK:SimpleButton;
      
      public var btn_helper:SimpleButton;
      
      public var defence:TextField;
      
      public var hp:TextField;
      
      public var iconContainer:MovieClip;
      
      public var mcGift:MovieClip;
      
      public var mcLevel0:MovieClip;
      
      public var mcLevel1:MovieClip;
      
      public var mcLevel2:MovieClip;
      
      public var mcLoc:MovieClip;
      
      public var spAttack:TextField;
      
      public var spDefence:TextField;
      
      public var speed:TextField;
      
      public var txtCharater:TextField;
      
      public var txtName:TextField;
      
      public var txtPetInfo:TextField;
      
      private var petId:int;
      
      private var petDateService:IPetDataService;
      
      private var petDetailedInfo:PetDetailedInfo;
      
      private var giftScore:int;
      
      public function CatchDonePanel(param1:Object)
      {
         var location:int;
         var targetSlotId:int;
         var player:PlayerBattleInfo;
         var ipetIcon:IPetIcon;
         var iconContainer:Sprite = null;
         var icon:PetIconContainer = null;
         var onLoaded:Function = null;
         var params:Object = param1;
         super();
         location = int(params.lc);
         SimpleButton(this.btn_helper).visible = location == 2;
         MovieClip(this.mcLoc).gotoAndStop(location);
         targetSlotId = int(params.tarSId);
         player = FightData.instance.playerInfo[targetSlotId];
         TextField(this.txtName).text = player.myPets[0].name;
         this.petId = params.pmId;
         SimpleButton(this.btnClose).addEventListener(MouseEvent.CLICK,this.onClose);
         SimpleButton(this.btnOK).addEventListener(MouseEvent.CLICK,this.onClose);
         SimpleButton(this.btn_helper).addEventListener(MouseEvent.CLICK,this.onClickHelper);
         iconContainer = Sprite(this.iconContainer);
         ipetIcon = ServicePool.instance.getService(IPetIcon);
         icon = ipetIcon.getPetIcon(player.myPets[0].viewId,PetIconType.LARGE,false);
         onLoaded = function(param1:PetIconEvent):void
         {
            icon.removeEventListener(PetIconEvent.ON_ICON_LOADED,onLoaded);
            DisplayUtil.stop(icon);
            DisplayUtil.scaleDisplay(icon,iconContainer.width,iconContainer.height);
            iconContainer.addChild(icon);
            DisplayUtil.middleDisplay(icon,140,120);
         };
         icon.addEventListener(PetIconEvent.ON_ICON_LOADED,onLoaded);
         icon.startLoad();
         this.petDateService = ServicePool.instance.getService(IPetDataService);
         this.petDateService.addEventListener(PetDataServiceEvent.RSPN_VIEW_SINGLE_PM,this.onViewSinglePm);
         PetClient.instance.viewSinglePM(this.petId);
      }
      
      private function onViewSinglePm(param1:PetDataServiceEvent) : void
      {
         var character:String = null;
         var evt:PetDataServiceEvent = param1;
         var id:int = int(evt.params.pm.pmPView.i);
         if(this.petId == id)
         {
            this.petDateService.removeEventListener(PetDataServiceEvent.RSPN_VIEW_SINGLE_PM,this.onViewSinglePm);
            this.petDetailedInfo = new PetDetailedInfo();
            this.petDetailedInfo.parseInfo(evt.params.pm);
            TextField(this.txtName).text = this.petDetailedInfo.name.toString();
            TextField(this.txtCharater).text = this.petDetailedInfo.character.toString();
            ArtNumberManager.setNumber([this.mcLevel0,this.mcLevel1,this.mcLevel2],this.petDetailedInfo.level);
            MovieClip(this.mcGift).gotoAndStop(this.getGiftFrame(this.petDetailedInfo));
            TextField(this.attack).text = this.petDetailedInfo.attack.toString();
            TextField(this.spAttack).text = this.petDetailedInfo.spAttack.toString();
            TextField(this.defence).text = this.petDetailedInfo.defence.toString();
            TextField(this.spDefence).text = this.petDetailedInfo.spDefence.toString();
            TextField(this.speed).text = this.petDetailedInfo.speed.toString();
            TextField(this.hp).text = this.petDetailedInfo.maxHp.toString();
            character = this.petDetailedInfo.character + PetCharacterMap.getPetCharacterMyDesc(this.petDetailedInfo.character);
            ServiceContainer.instance.tryGetService(IPetDictionaryDataService,function(param1:IPetDictionaryDataService, param2:Object):void
            {
               var _loc3_:int = int(petDetailedInfo.raceId);
               var _loc4_:PetDictionaryDataItem = param1.getDataItemByRaceId(_loc3_);
               TextField(getChildByName("txtPetInfo")).text = _loc4_.petIntro;
            });
         }
      }
      
      private function getGiftFrame(param1:PetDetailedInfo) : int
      {
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc2_:Array = [];
         _loc2_.push(this.value2StarNum(param1.indAtt));
         _loc2_.push(this.value2StarNum(param1.indDef));
         _loc2_.push(this.value2StarNum(param1.indSAtt));
         _loc2_.push(this.value2StarNum(param1.indSDef));
         _loc2_.push(this.value2StarNum(param1.indHP));
         _loc2_.push(this.value2StarNum(param1.indSpd));
         this.giftScore = 0;
         for each(_loc3_ in _loc2_)
         {
            this.giftScore += _loc3_;
         }
         _loc4_ = this.giftScore / 5;
         if(_loc4_ == 0)
         {
            _loc4_ = 1;
         }
         return _loc4_;
      }
      
      private function value2StarNum(param1:int) : int
      {
         if(param1 >= 0 && param1 <= 10)
         {
            return 1;
         }
         if(param1 >= 11 && param1 <= 20)
         {
            return 2;
         }
         if(param1 >= 21 && param1 <= 30)
         {
            return 3;
         }
         if(param1 >= 31 && param1 <= 50)
         {
            return 4;
         }
         if(param1 >= 51 && param1 <= 62)
         {
            return 5;
         }
         return 0;
      }
      
      private function onClickHelper(param1:MouseEvent) : void
      {
         var evt:MouseEvent = param1;
         ProgressFullSprite.show();
         ResScheduler.getResource("pet/petpackagehelper",function(param1:IShowPanel):void
         {
            ProgressFullSprite.close();
            param1.showPanel();
         },"mmo.petpackagehelper.HelpPanel",null,null,ResPriority.NORMAL,true,FightData.instance.applicationDomain);
      }
      
      private function onGetUpdateMessage(param1:PetDataServiceEvent) : void
      {
         var _loc2_:int = int(param1.params.pm.pmPView.i);
         if(this.petId == _loc2_)
         {
            this.petDateService.removeEventListener(PetDataServiceEvent.RSPN_VIEW_SINGLE_PM,this.onGetUpdateMessage);
            this.petDetailedInfo.parseInfo(param1.params.pm);
            TextField(this.txtName).text = this.petDetailedInfo.nickname;
         }
      }
      
      private function onClose(param1:MouseEvent) : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.CLICK_RESULT_PANEL));
         this.petDateService.removeEventListener(PetDataServiceEvent.RSPN_VIEW_SINGLE_PM,this.onViewSinglePm);
         this.petDateService.removeEventListener(PetDataServiceEvent.RSPN_VIEW_SINGLE_PM,this.onGetUpdateMessage);
      }
   }
}

