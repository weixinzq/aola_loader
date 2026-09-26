package mmo.petpackage.panel.inclusion
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.battleeffmv.BattleEffMv;
   import mmo.common.bonus.ShowBonusHelper;
   import mmo.common.dialog.NewDialog;
   import mmo.common.display.DisplayIndexManager;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.PetClient2;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.material.MaterialClient;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.callback.FunCallInfo;
   import mmo.interfaces.material.godcard.IGodCardService;
   import mmo.interfaces.material.godcard.UserGodCard;
   import mmo.interfaces.pet.data.GodCardInfo;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.petcardoptimize.IPetCardOptimizeService;
   import mmo.interfaces.secondpwd.ISecondPwdService;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.data.GodCardViewEqued;
   import mmo.petpackage.data.PetDetailDataMap;
   import mmo.play.activity.helper.Panel_Helper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol948")]
   public class GodCardList extends Sprite implements IDispose
   {
      
      private static const CARD_WITH_HEIGGHT:int = 60;
      
      private static const CMD_BATTLE_EFF_CHANGE:String = "54_InformPetCE";
      
      private static const cardViewName:String = "view";
      
      private static const tipsCardViewName:String = "tipscardview";
      
      public var area:MovieClip;
      
      public var card0:MovieClip;
      
      public var card1:MovieClip;
      
      public var tipsPanel:MovieClip;
      
      private var godCardService:IGodCardService;
      
      private const UniqueName:String = "GodcardMenu_unique_name";
      
      private var cards:Array = null;
      
      private var indexManager:DisplayIndexManager = new DisplayIndexManager();
      
      private var _oldBattleEff:int;
      
      private var _newBattleEff:int;
      
      private var _battleEffChangetype:int;
      
      private var BATTLE_CHANGE_FEN_JIE:int = 1;
      
      private var _petId:int = -1;
      
      private var tipsCards:Array = null;
      
      private var tipsCardNameTxts:Array = null;
      
      private var _area:MovieClip;
      
      private var _tipsPanel:MovieClip;
      
      private var _godSvr:IGodCardService;
      
      public function GodCardList()
      {
         super();
         this.initPars();
         this.initFuns();
      }
      
      private function initPars() : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:TextField = null;
         this._area = this.area as MovieClip;
         this.cards = [this.card0,this.card1];
         this.tipsCardNameTxts = [];
         this.tipsCards = [];
         this._tipsPanel = this.getChildByName("tipsPanel") as MovieClip;
         this._tipsPanel.visible = false;
         var _loc1_:int = 0;
         while(_loc1_ < this.cards.length)
         {
            _loc2_ = this._tipsPanel.getChildByName("card" + _loc1_) as MovieClip;
            _loc3_ = this._tipsPanel.getChildByName("txtName" + _loc1_) as TextField;
            this.tipsCards.push(_loc2_);
            this.tipsCardNameTxts.push(_loc3_);
            _loc1_++;
         }
         this.godCardService = ServiceContainer.getService(IGodCardService) as IGodCardService;
      }
      
      private function initFuns() : void
      {
         var _loc1_:Sprite = null;
         SocketClient.instance.addEventListener(MaterialClient.cmdDressGodCards,this.onCmdEquip);
         for each(_loc1_ in this.tipsCards)
         {
            _loc1_.buttonMode = true;
            _loc1_.addEventListener(MouseEvent.CLICK,this.onClick);
            _loc1_.addEventListener(MouseEvent.ROLL_OUT,this.onRollOut);
         }
         this.indexManager.registerSome(this.cards);
         this._godSvr = ServiceContainer.getService(IGodCardService) as IGodCardService;
         this._area.addEventListener(MouseEvent.ROLL_OVER,this.onAreaOverListener);
         this._area.addEventListener(MouseEvent.ROLL_OUT,this.onAreaOutListener);
         this._tipsPanel.addEventListener(MouseEvent.ROLL_OVER,this.onAreaOverListener);
         this._tipsPanel.addEventListener(MouseEvent.ROLL_OUT,this.onAreaOutListener);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onPetDetailedCached);
      }
      
      private function onPetDetailedCached(param1:PetPackageEvent) : void
      {
         var _loc3_:Array = null;
         var _loc4_:int = 0;
         var _loc5_:GodCardInfo = null;
         this.removeCardView();
         var _loc2_:PetBriefInfo = PetDetailDataMap.instance.getPetDetailInfo(param1.params.id);
         if(PetDetailDataMap.instance.checkCache(_loc2_.id))
         {
            _loc2_ = PetDetailDataMap.instance.getPetDetailInfo(_loc2_.id);
         }
         if(_loc2_ != null)
         {
            _loc3_ = _loc2_.gc;
            if(_loc3_ != null)
            {
            }
            if(!_loc2_.hadGodCard())
            {
               this._area.mouseEnabled = false;
               TipsManager.getInstance().addTips(this.cards[0],"还没穿上神兵哦！");
            }
            else
            {
               this._area.mouseEnabled = true;
               TipsManager.getInstance().removeTips(this.cards[0]);
            }
            _loc4_ = 0;
            while(_loc4_ < _loc3_.length)
            {
               _loc5_ = _loc3_[_loc4_] as GodCardInfo;
               this.setCardView(_loc4_,_loc5_.uniqueId);
               this.setTipsCardView(_loc4_,_loc2_.id,_loc5_.materialId,_loc5_.uniqueId);
               _loc4_++;
            }
         }
      }
      
      private function setCardView(param1:int, param2:int = -1) : void
      {
         var _loc3_:Sprite = this.cards[param1] as Sprite;
         var _loc4_:Sprite = _loc3_.getChildByName(cardViewName) as Sprite;
         if(_loc4_ != null)
         {
            _loc3_.removeChild(_loc4_);
         }
         if(param2 == -1)
         {
            return;
         }
         var _loc5_:DisplayObject = this._godSvr.getGodCardViewBySerial(param2,param1,false);
         _loc5_.name = cardViewName;
         _loc3_.addChild(_loc5_);
         DisplayUtil.scaleDisplay(_loc5_,CARD_WITH_HEIGGHT,CARD_WITH_HEIGGHT);
         DisplayUtil.middleDisplay(_loc5_,CARD_WITH_HEIGGHT,CARD_WITH_HEIGGHT);
      }
      
      private function setTipsCardView(param1:int, param2:int, param3:int, param4:int) : void
      {
         var _loc5_:Sprite = this.tipsCards[param1] as Sprite;
         var _loc6_:Sprite = _loc5_.getChildByName(tipsCardViewName) as Sprite;
         if(_loc6_ != null)
         {
            _loc5_.removeChild(_loc6_);
         }
         if(param4 == -1)
         {
            (this.tipsCards[param1] as MovieClip).buttonMode = false;
            this.tipsCardNameTxts[param1].text = "??????";
            return;
         }
         (this.tipsCards[param1] as MovieClip).buttonMode = true;
         var _loc7_:GodCardViewEqued = new GodCardViewEqued(param2,param3,param4,2);
         _loc7_.x = 13;
         _loc7_.y = 9;
         _loc7_.name = tipsCardViewName;
         var _loc8_:String = _loc7_.cardName;
         DisplayUtil.middleDisplay(_loc7_,_loc5_.width,_loc5_.height);
         _loc5_.addChild(_loc7_);
         this.tipsCardNameTxts[param1].text = _loc8_;
      }
      
      private function onCmdEquip(param1:SocketClientEvent) : void
      {
         var _loc2_:Object = null;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:UserGodCard = null;
         if(param1.params.r == 1)
         {
            _loc2_ = param1.params.ga;
            _loc3_ = int(param1.params.si);
            _loc4_ = int(_loc2_.pi);
            _loc5_ = this._godSvr.getMyGodCardBySerial(_loc2_.ui);
            this.setCardView(_loc3_,_loc2_.ui);
            this.setTipsCardView(_loc3_,_loc4_,_loc5_.materialId,_loc2_.ui);
         }
         else
         {
            NewDialog.showFailMessage("装备错误 " + param1.params.r);
         }
      }
      
      private function onRollOut(param1:MouseEvent) : void
      {
         var _loc2_:DisplayObjectContainer = param1.currentTarget as DisplayObjectContainer;
         this.removeGodcardMenu(_loc2_);
      }
      
      private function onAreaOverListener(param1:MouseEvent) : void
      {
         this._tipsPanel.visible = true;
      }
      
      private function onAreaOutListener(param1:MouseEvent) : void
      {
         this._tipsPanel.visible = false;
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc4_:FunCallInfo = null;
         var _loc6_:DisplayObject = null;
         param1.stopImmediatePropagation();
         var _loc2_:Sprite = param1.currentTarget as Sprite;
         var _loc3_:GodCardViewEqued = _loc2_.getChildByName(tipsCardViewName) as GodCardViewEqued;
         var _loc5_:ISecondPwdService = ServiceContainer.getService(ISecondPwdService) as ISecondPwdService;
         if(null != _loc3_)
         {
            _loc6_ = param1.target as DisplayObject;
            this.removeGodcardMenu(_loc2_);
            switch(_loc6_.name)
            {
               case "btntablevelup":
                  _loc4_ = new FunCallInfo(this.showEquipFun,this,[5,_loc3_.petId,_loc3_.cardId,_loc3_.uniqueId]);
                  _loc5_.verify(_loc4_);
                  break;
               case "btndecompose":
                  _loc4_ = new FunCallInfo(this.showDecompose,this,[_loc3_.uniqueId,_loc3_.petId]);
                  _loc5_.verify(_loc4_);
                  break;
               case "btnseal":
                  _loc4_ = new FunCallInfo(this.showEquipSeal,this,[_loc3_.petId,_loc3_.uniqueId]);
                  _loc5_.verify(_loc4_);
                  break;
               case "btnsynthesis":
                  this.showSynthesisFun();
                  break;
               default:
                  this.showGodCardMenu(_loc2_);
            }
         }
      }
      
      private function showSynthesisFun() : void
      {
         ModalDialogManager.getInstance().clearAll();
         var _loc1_:String = "activityres/activity201030/shenbingzhuxing/shenbingzhuxing_code";
         var _loc2_:String = "mmo.activity201030.shenbingzhuxing.panel.SBZX_MainPl";
         Panel_Helper.loadResAndShow(_loc1_,_loc2_);
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
      
      private function showEquipFun(param1:int, param2:int, param3:int, param4:int) : void
      {
         var tab:int = param1;
         var pid:int = param2;
         var cardid:int = param3;
         var uniqueId:int = param4;
         ModalDialogManager.getInstance().clearAll();
         ProgressFullSprite.show();
         ServiceContainer.instance.tryGetService(IPetCardOptimizeService,function(param1:IPetCardOptimizeService, param2:Object):void
         {
            ProgressFullSprite.close();
            param1.showPanel();
            param1.changeFunctionTab(tab,pid,cardid,uniqueId);
         });
      }
      
      private function showGodCardMenu(param1:DisplayObjectContainer) : void
      {
         var _loc2_:MovieClip = param1.getChildByName(this.UniqueName) as MovieClip;
         var _loc3_:GodCardViewEqued = param1.getChildByName(tipsCardViewName) as GodCardViewEqued;
         if(null != _loc2_)
         {
            _loc2_.initMenu(_loc3_.uniqueId);
            return;
         }
         this.loadGodCardMenu(param1,_loc3_);
      }
      
      private function loadGodCardMenu(param1:DisplayObjectContainer, param2:GodCardViewEqued) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function removeGodcardMenu(param1:DisplayObjectContainer) : void
      {
         var _loc2_:MovieClip = param1.getChildByName(this.UniqueName) as MovieClip;
         if(null == _loc2_)
         {
            return;
         }
         DisplayUtil.stopAndRemove(_loc2_);
      }
      
      private function showDecompose(param1:int, param2:int) : void
      {
         var uniqueId:int = param1;
         var pId:int = param2;
         var callback:Function = function():*
         {
            onDecompose(uniqueId,pId);
         };
         Panel_Helper.loadResAndShow("godcardpanel/godcardpanel","mmo.pet.godcard.GodCardDecomposeConfirm",{
            "uniqueId":uniqueId,
            "succallback":callback
         });
      }
      
      private function onDecompose(param1:int, param2:int) : void
      {
         this._petId = param2;
         this._battleEffChangetype = this.BATTLE_CHANGE_FEN_JIE;
         SocketClient.instance.addEventListener(MaterialClient.cmdDecomposeGodCards,this.onFreshCard);
         SocketClient.instance.sendXtMessage("MaterialExtension",MaterialClient.cmdDecomposeGodCards,{"ui":param1});
      }
      
      private function onFreshCard(param1:SocketClientEvent) : void
      {
         var _loc2_:Sprite = null;
         var _loc3_:Sprite = null;
         SocketClient.instance.removeEventListener(MaterialClient.cmdDecomposeGodCards,this.onFreshCard);
         if(param1.params.r == 1)
         {
            if(param1.params.si < 0)
            {
               throw new Error("分解位置错误" + param1.params.si);
            }
            PetClient.instance.viewSinglePM(this._petId);
            this.setTipsCardView(param1.params.si,-1,-1,-1);
            _loc2_ = this.cards[param1.params.si] as Sprite;
            _loc3_ = _loc2_.getChildByName(cardViewName) as Sprite;
            if(_loc3_ != null)
            {
               DisplayUtil.stopAndRemove(_loc3_);
            }
            ShowBonusHelper.showBonus(param1.params.bn);
         }
         else
         {
            NewDialog.showFailMessage("分解失败" + param1.params.r);
         }
      }
      
      private function removeCardView() : void
      {
         var _loc1_:Sprite = null;
         var _loc2_:Sprite = null;
         var _loc3_:MovieClip = null;
         var _loc4_:GodCardViewEqued = null;
         for each(_loc1_ in this.cards)
         {
            _loc3_ = _loc1_.getChildByName(cardViewName) as MovieClip;
            if(_loc3_ != null)
            {
               _loc1_.removeChild(_loc3_);
            }
         }
         for each(_loc2_ in this.tipsCards)
         {
            _loc4_ = _loc2_.getChildByName(tipsCardViewName) as GodCardViewEqued;
            if(_loc4_ != null)
            {
               _loc2_.removeChild(_loc4_);
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
         SocketClient.instance.removeEventListener(MaterialClient.cmdDressGodCards,this.onCmdEquip);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onPetDetailedCached);
         this.indexManager.dispose();
         for each(_loc1_ in this.tipsCards)
         {
            _loc1_.removeEventListener(MouseEvent.ROLL_OUT,this.onRollOut);
            _loc1_.removeEventListener(MouseEvent.CLICK,this.onClick);
         }
         this._area.removeEventListener(MouseEvent.ROLL_OVER,this.onAreaOverListener);
         this._area.removeEventListener(MouseEvent.ROLL_OUT,this.onAreaOutListener);
         this._tipsPanel.removeEventListener(MouseEvent.ROLL_OVER,this.onAreaOverListener);
         this._tipsPanel.removeEventListener(MouseEvent.ROLL_OUT,this.onAreaOutListener);
         SocketClient.instance.removeEventListener(PetClient2.cmdEquip,this.onCmdEquip);
      }
   }
}

