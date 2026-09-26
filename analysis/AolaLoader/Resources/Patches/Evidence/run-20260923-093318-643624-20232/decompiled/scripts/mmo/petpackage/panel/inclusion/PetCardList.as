package mmo.petpackage.panel.inclusion
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.GlobalVariable;
   import mmo.common.ProgressFullSprite;
   import mmo.common.battleeffmv.BattleEffMv;
   import mmo.common.bonus.ShowBonusHelper;
   import mmo.common.display.DisplayIndexManager;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.shareobject.LocalStore;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.PetClient2;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.material.PetCard3Client;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.callback.FunCallInfo;
   import mmo.interfaces.material.petcard.IPetCardService;
   import mmo.interfaces.material.petcard.PetCard;
   import mmo.interfaces.material.petcard3.IPetCard3Service;
   import mmo.interfaces.material.petcard3.PetCard3TipsHelper;
   import mmo.interfaces.material.petcard3.UserPetCard3;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.interfaces.pet.data.EquipmentInfo;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.petcardoptimize.IPetCardOptimizeService;
   import mmo.interfaces.secondpwd.ISecondPwdService;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.controller.helper.TabJumpHelper;
   import mmo.petpackage.data.PetDetailDataMap;
   import mmo.petpackage.data.ViewSelecteded;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.activity.helper.Pet_Helper;
   import mmo.play.actthings.helper.ActComHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1048")]
   public class PetCardList extends Sprite implements IDispose
   {
      
      private static const CMD_BATTLE_EFF_CHANGE:String = "54_InformPetCE";
      
      private static const cardViewName:String = "view";
      
      public var card0:MovieClip;
      
      public var card1:MovieClip;
      
      public var card2:MovieClip;
      
      public var card3:MovieClip;
      
      public var mcLabel_0:MovieClip;
      
      public var mcLabel_1:MovieClip;
      
      public var mcLabel_2:MovieClip;
      
      public var mcLabel_3:MovieClip;
      
      public var mcShow:MovieClip;
      
      private const cmdRemoveEquip:String = "54e_2";
      
      private var petCardService:IPetCardService;
      
      private var petCard3S:IPetCard3Service;
      
      private var petId:int = -1;
      
      private var cardId:int = -1;
      
      private var equipId:int = -1;
      
      private const UniqueName:String = "Petcard3Menu_unique_name";
      
      private var cards:Array = null;
      
      private var labels:Array = null;
      
      private var indexManager:DisplayIndexManager = new DisplayIndexManager();
      
      private var _oldBattleEff:int;
      
      private var _newBattleEff:int;
      
      private var _battleEffChangetype:int;
      
      private var BATTLE_CHANGE_FEN_JIE:int = 1;
      
      private var _curPetInfo:PetBriefInfo;
      
      private var _firstTabIndex:int = 0;
      
      private var _showCardList:Boolean = LocalStore.getValue(PetPackageEvent.EQUIP_SHOW_KEY) ? Boolean(LocalStore.getValue(PetPackageEvent.EQUIP_SHOW_KEY)["showCard"]) : true;
      
      public function PetCardList()
      {
         super();
         this.initPars();
         this.initFuns();
      }
      
      private function initPars() : void
      {
         this.cards = [this.card0,this.card1,this.card2,this.card3];
         this.labels = [this.mcLabel_0,this.mcLabel_1,this.mcLabel_2,this.mcLabel_3];
         this.petCard3S = ServiceContainer.getService(IPetCard3Service) as IPetCard3Service;
         this.petCardService = ServiceContainer.instance.getService("PetCardService") as IPetCardService;
      }
      
      private function initFuns() : void
      {
         var _loc1_:Sprite = null;
         var _loc2_:MovieClip = null;
         SocketClient.instance.addEventListener(PetClient2.cmdEquip,this.onCmdEquip);
         for each(_loc1_ in this.cards)
         {
            _loc1_.buttonMode = true;
            _loc1_.addEventListener(MouseEvent.CLICK,this.onClick);
            _loc1_.addEventListener(MouseEvent.ROLL_OUT,this.onRollOut);
         }
         for each(_loc2_ in this.labels)
         {
            _loc2_.buttonMode = true;
            _loc2_.addEventListener(MouseEvent.CLICK,this.onClickLabel);
         }
         this.petCard3S.addEventListener(PetCard3Client.cmdReIdentify,this.oncmdReIdentify);
         this.indexManager.registerSome(this.cards);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onPetDetailedCached);
         CommonEventDispatcher.instance.addEventListener("GQSimpleSkillChange",this.onGQSimpleSkillChange);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_INFO_TAB_CHANGED,this.onChangeFirstTab);
         this.addEventListener(MouseEvent.CLICK,this.onClickContainer);
      }
      
      private function onChangeFirstTab(param1:PetPackageEvent) : void
      {
         this._firstTabIndex = param1.params.firstTab;
         this.refreshCardListView();
      }
      
      private function onGQSimpleSkillChange(param1:CommonEvent) : void
      {
         this.loadPetCard(this._curPetInfo,true);
      }
      
      private function onPetDetailedCached(param1:PetPackageEvent) : void
      {
         this.removeCardView();
         var _loc2_:PetBriefInfo = PetDetailDataMap.instance.getPetDetailInfo(param1.params.id);
         if(PetDetailDataMap.instance.checkCache(_loc2_.id))
         {
            _loc2_ = PetDetailDataMap.instance.getPetDetailInfo(_loc2_.id);
         }
         this._curPetInfo = _loc2_;
         this.loadPetCard(_loc2_);
         this.refreshCardListView();
      }
      
      private function loadPetCard(param1:PetBriefInfo, param2:Boolean = false) : void
      {
         var _loc3_:Array = null;
         var _loc4_:Boolean = false;
         var _loc5_:IGameOptionService = null;
         var _loc6_:* = false;
         var _loc7_:EquipmentInfo = null;
         var _loc8_:PetCard = null;
         var _loc9_:Sprite = null;
         var _loc10_:ViewSelecteded = null;
         if(param1 != null)
         {
            _loc3_ = param1.eqp;
            if(_loc3_ != null)
            {
            }
            _loc4_ = true;
            _loc5_ = ServiceContainer.getService(IGameOptionService) as IGameOptionService;
            if(_loc5_.isGQSimpleSkillView)
            {
               _loc4_ = false;
            }
            _loc6_ = param1.usingGQSkillType == 1;
            for each(_loc7_ in _loc3_)
            {
               _loc8_ = this.petCardService.getPetCardById(_loc7_.id);
               _loc9_ = this.cards[_loc8_.type] as Sprite;
               if(param2)
               {
                  _loc10_ = _loc9_.getChildByName(cardViewName) as ViewSelecteded;
               }
               else
               {
                  _loc10_ = new ViewSelecteded(param1.id,_loc8_.id,_loc7_.equipid);
                  _loc10_.x = 18;
                  _loc10_.y = 12;
                  _loc10_.name = cardViewName;
                  _loc9_.addChild(_loc10_);
               }
               TipsManager.getInstance().replaceComplexTips(_loc10_,PetCard3TipsHelper.getNameBySerial(_loc7_.equipid),PetCard3TipsHelper.getHtmlTipsBySerial(_loc7_.equipid,_loc4_,_loc6_));
            }
         }
         this.updateCardTips();
         this.updateLabels();
      }
      
      private function loadPetCard3View(param1:EquipmentInfo, param2:int) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function onCmdEquip(param1:SocketClientEvent) : void
      {
         var _loc2_:UserPetCard3 = null;
         var _loc3_:PetCard = null;
         var _loc4_:Sprite = null;
         var _loc5_:ViewSelecteded = null;
         var _loc6_:Sprite = null;
         if(param1.params.res)
         {
            _loc2_ = this.petCard3S.getMyPetCard3BySerial(param1.params.cid);
            _loc3_ = _loc2_.material as PetCard;
            _loc4_ = this.cards[_loc3_.type] as Sprite;
            _loc5_ = new ViewSelecteded(param1.params.pid,this.cardId,param1.params.cid);
            _loc5_.x = 18;
            _loc5_.y = 12;
            _loc5_.name = cardViewName;
            TipsManager.getInstance().addComplexTips(_loc5_ as InteractiveObject,_loc3_.name,_loc3_.description);
            _loc6_ = _loc4_.getChildByName(cardViewName) as Sprite;
            if(_loc6_ != null)
            {
               _loc4_.removeChild(_loc6_);
            }
            _loc4_.addChild(_loc5_);
            this.updateCardTips();
            this.updateLabels();
         }
      }
      
      private function oncmdReIdentify(param1:Event) : void
      {
         PetClient.instance.viewAllPM();
      }
      
      private function onRollOut(param1:MouseEvent) : void
      {
         var _loc2_:DisplayObjectContainer = param1.currentTarget as DisplayObjectContainer;
         this.removePetcard3Menu(_loc2_);
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc4_:FunCallInfo = null;
         var _loc6_:DisplayObject = null;
         param1.stopImmediatePropagation();
         var _loc2_:Sprite = param1.currentTarget as Sprite;
         var _loc3_:ViewSelecteded = _loc2_.getChildByName(cardViewName) as ViewSelecteded;
         var _loc5_:ISecondPwdService = ServiceContainer.getService(ISecondPwdService) as ISecondPwdService;
         if(null != _loc3_)
         {
            _loc6_ = param1.target as DisplayObject;
            this.removePetcard3Menu(_loc2_);
            switch(_loc6_.name)
            {
               case "btntablevelup":
                  _loc4_ = new FunCallInfo(this.showEquipFun,this,[0,_loc3_.petId,_loc3_.cardId,_loc3_.equipId]);
                  _loc5_.verify(_loc4_);
                  break;
               case "btnadvance":
                  _loc4_ = new FunCallInfo(this.showEquipAdvance,this,[_loc3_.petId,_loc3_.cardId,_loc3_.equipId]);
                  _loc5_.verify(_loc4_);
                  break;
               case "btnreidentify":
                  _loc4_ = new FunCallInfo(this.showEquipFun,this,[4,_loc3_.petId,_loc3_.cardId,_loc3_.equipId]);
                  _loc5_.verify(_loc4_);
                  break;
               case "btndecompose":
                  _loc4_ = new FunCallInfo(this.showConfirm,this,[_loc3_]);
                  _loc5_.verify(_loc4_);
                  break;
               case "btnseal":
                  _loc4_ = new FunCallInfo(this.showEquipSeal,this,[_loc3_.petId,_loc3_.equipId]);
                  _loc5_.verify(_loc4_);
                  break;
               default:
                  this.showPetcard3Menu(_loc2_);
            }
         }
         else
         {
            GlobalVariable.instance.setVar("petcard3_tab",this.cards.indexOf(_loc2_));
            TabJumpHelper.changeFirstTab(2);
            TabJumpHelper.changeSecondTab(1);
            this.refreshCardTab(this.cards.indexOf(_loc2_));
         }
      }
      
      private function onClickLabel(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         GlobalVariable.instance.setVar("petcard_label_package",true);
         this.updateLabels();
      }
      
      private function onClickContainer(param1:MouseEvent) : void
      {
         if(param1.target.name == "btnchangeshow")
         {
            this._showCardList = !this._showCardList;
            LocalStore.setValue(PetPackageEvent.EQUIP_SHOW_KEY,{"showCard":this._showCardList});
            PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_CARD_SHOW_STATUS_CHANGED,{"showCard":this._showCardList}));
            this.refreshCardListView();
         }
      }
      
      private function refreshCardListView() : void
      {
         var _loc1_:Boolean = true;
         var _loc2_:* = false;
         if(Boolean(this._curPetInfo) && Boolean(Pet_Helper.checkPetIsGQPet(this._curPetInfo.raceId)))
         {
            _loc1_ = this._showCardList || this._firstTabIndex == 2;
            _loc2_ = this._firstTabIndex != 2;
         }
         var _loc3_:int = 0;
         while(_loc3_ < this.cards.length)
         {
            this.cards[_loc3_].visible = _loc1_;
            _loc3_++;
         }
         ActComHelper.setMcFrame(this,"mcShow",this._showCardList ? 1 : 2);
         ActComHelper.setVisible(this,"mcShow",_loc2_);
         this.updateLabels();
      }
      
      private function showEquipSeal(param1:int, param2:int) : void
      {
         var _loc3_:String = "activityres/activity150220/zhuanshucard/ndcode";
         var _loc4_:String = "mmo.activity150220.zhuanshucard.sealpl.NDCardSealPl";
         Panel_Helper.loadResAndShow(_loc3_,_loc4_,{
            "pid":param1,
            "serial":param2
         });
      }
      
      private function refreshCardTab(param1:int = 0) : void
      {
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("petcard3_tab_evt",{"tab":param1}));
      }
      
      private function showEquipAdvance(param1:int, param2:int, param3:int) : void
      {
         var pid:int = param1;
         var cardid:int = param2;
         var serial:int = param3;
         ProgressFullSprite.show();
         ServiceContainer.instance.tryGetService(IPetCardOptimizeService,function(param1:IPetCardOptimizeService, param2:Object):void
         {
            ProgressFullSprite.close();
            param1.showPanel();
            param1.changeFunctionTab(3,pid,cardid,serial);
         });
      }
      
      private function showEquipFun(param1:int, param2:int, param3:int, param4:int) : void
      {
         var tab:int = param1;
         var pid:int = param2;
         var cardid:int = param3;
         var serial:int = param4;
         ModalDialogManager.getInstance().clearAll();
         ProgressFullSprite.show();
         ServiceContainer.instance.tryGetService(IPetCardOptimizeService,function(param1:IPetCardOptimizeService, param2:Object):void
         {
            ProgressFullSprite.close();
            param1.showPanel();
            param1.changeFunctionTab(tab,pid,cardid,serial);
         });
      }
      
      private function showPetcard3Menu(param1:DisplayObjectContainer) : void
      {
         var _loc2_:MovieClip = param1.getChildByName(this.UniqueName) as MovieClip;
         var _loc3_:ViewSelecteded = param1.getChildByName(cardViewName) as ViewSelecteded;
         if(null != _loc2_)
         {
            _loc2_.initMenu(_loc3_.equipId);
            return;
         }
         this.loadPetCard3Menu(param1,_loc3_);
      }
      
      private function loadPetCard3Menu(param1:DisplayObjectContainer, param2:ViewSelecteded) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function removePetcard3Menu(param1:DisplayObjectContainer) : void
      {
         var _loc2_:MovieClip = param1.getChildByName(this.UniqueName) as MovieClip;
         if(null == _loc2_)
         {
            return;
         }
         DisplayUtil.stopAndRemove(_loc2_);
      }
      
      private function showConfirm(param1:ViewSelecteded) : void
      {
         var sp:Sprite = null;
         var viewSelected:ViewSelecteded = param1;
         this.petId = viewSelected.petId;
         this.cardId = viewSelected.cardId;
         this.equipId = viewSelected.equipId;
         sp = new PetCardUnConfirm() as Sprite;
         this.addPetBattleEffListener();
         sp.addEventListener(MouseEvent.CLICK,function(param1:MouseEvent):void
         {
            if(param1.target.name == "btnClose")
            {
               removePetBattleEffListener();
               ModalDialogManager.getInstance().removeModalDialog(sp);
            }
            else if(param1.target.name == "btnUninConfirm")
            {
               ModalDialogManager.getInstance().removeModalDialog(sp);
               onOK();
            }
         });
         ModalDialogManager.getInstance().addModalDialog(sp);
      }
      
      private function onOK() : void
      {
         this._battleEffChangetype = this.BATTLE_CHANGE_FEN_JIE;
         SocketClient.instance.addEventListener(this.cmdRemoveEquip,this.onFreshCard);
         SocketClient.instance.sendXtMessage("PetExtension2",this.cmdRemoveEquip,{
            "cid":this.equipId,
            "pid":this.petId
         });
      }
      
      private function onFreshCard(param1:SocketClientEvent) : void
      {
         var _loc2_:PetCard = null;
         var _loc3_:Sprite = null;
         var _loc4_:Sprite = null;
         SocketClient.instance.removeEventListener(this.cmdRemoveEquip,this.onFreshCard);
         if(param1.params.suc)
         {
            _loc2_ = this.petCardService.getPetCardById(this.cardId);
            _loc3_ = this.cards[_loc2_.type] as Sprite;
            _loc4_ = _loc3_.getChildByName(cardViewName) as Sprite;
            if(_loc4_ != null)
            {
               DisplayUtil.stopAndRemove(_loc4_);
            }
            ShowBonusHelper.showBonus(param1.params.bn);
            PetClient.instance.viewAllPM();
         }
         PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_GO_2_SINGLE_PM,{"id":this.petId}));
      }
      
      private function removeCardView() : void
      {
         var _loc1_:Sprite = null;
         var _loc2_:ViewSelecteded = null;
         for each(_loc1_ in this.cards)
         {
            _loc2_ = _loc1_.getChildByName(cardViewName) as ViewSelecteded;
            if(_loc2_ != null)
            {
               _loc1_.removeChild(_loc2_);
            }
         }
      }
      
      private function updateCardTips() : void
      {
         var _loc1_:Sprite = null;
         var _loc2_:ViewSelecteded = null;
         for each(_loc1_ in this.cards)
         {
            _loc2_ = _loc1_.getChildByName(cardViewName) as ViewSelecteded;
            if(_loc2_ != null)
            {
               TipsManager.getInstance().removeTips(_loc1_);
            }
            else
            {
               TipsManager.getInstance().addTips(_loc1_,"还没穿上装备哦！");
            }
         }
      }
      
      private function updateLabels() : void
      {
         var _loc3_:EquipmentInfo = null;
         var _loc4_:PetCard = null;
         var _loc1_:int = 0;
         while(_loc1_ < 4)
         {
            ActComHelper.setVisible(this,"mcLabel_" + _loc1_,false);
            _loc1_++;
         }
         if(!this._showCardList)
         {
            return;
         }
         if(!this._curPetInfo)
         {
            return;
         }
         var _loc2_:Array = this._curPetInfo.eqp;
         for each(_loc3_ in _loc2_)
         {
            _loc4_ = this.petCardService.getPetCardById(_loc3_.id);
            ActComHelper.setVisible(this,"mcLabel_" + _loc4_.type,!GlobalVariable.instance.getVar("petcard_label_package"));
            if(!GlobalVariable.instance.getVar("petcard_label_package"))
            {
               TipsManager.getInstance().replaceTips(this.labels[_loc4_.type],"当前显示装备分类图标，点击后可本次登录隐藏。");
               ActComHelper.setMcFrame(this,"mcLabel_" + _loc4_.type,Boolean(_loc4_.limitRaceId) && _loc4_.limitRaceId.indexOf(this._curPetInfo.raceId) >= 0 ? (_loc4_.isInferior ? 2 : 1) : 3);
            }
         }
      }
      
      private function onBattleEffChange(param1:SocketClientEvent) : void
      {
         this._oldBattleEff = param1.params.oldCE;
         this._newBattleEff = param1.params.newCE;
         this.removePetBattleEffListener();
         this.playBattleEffChangeMv();
      }
      
      private function playBattleEffChangeMv() : void
      {
         var _loc1_:int = Math.abs(this._newBattleEff - this._oldBattleEff);
         switch(this._battleEffChangetype)
         {
            case this.BATTLE_CHANGE_FEN_JIE:
               BattleEffMv.playResolveEquipMv(_loc1_);
         }
      }
      
      private function addPetBattleEffListener() : void
      {
         SocketClient.instance.addEventListener(CMD_BATTLE_EFF_CHANGE,this.onBattleEffChange);
      }
      
      private function removePetBattleEffListener() : void
      {
         SocketClient.instance.removeEventListener(CMD_BATTLE_EFF_CHANGE,this.onBattleEffChange);
      }
      
      public function dispose() : void
      {
         var _loc1_:Sprite = null;
         var _loc2_:MovieClip = null;
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_INFO_TAB_CHANGED,this.onChangeFirstTab);
         this.removeEventListener(MouseEvent.CLICK,this.onClickContainer);
         CommonEventDispatcher.instance.removeEventListener("GQSimpleSkillChange",this.onGQSimpleSkillChange);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onPetDetailedCached);
         this.indexManager.dispose();
         this.petCard3S.removeEventListener(PetCard3Client.cmdReIdentify,this.oncmdReIdentify);
         for each(_loc1_ in this.cards)
         {
            _loc1_.removeEventListener(MouseEvent.ROLL_OUT,this.onRollOut);
            _loc1_.removeEventListener(MouseEvent.CLICK,this.onClick);
         }
         for each(_loc2_ in this.labels)
         {
            _loc2_.removeEventListener(MouseEvent.CLICK,this.onClickLabel);
         }
         SocketClient.instance.removeEventListener(PetClient2.cmdEquip,this.onCmdEquip);
         this._curPetInfo = null;
      }
   }
}

