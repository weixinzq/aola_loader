package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.tips.NotifyQueue;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.material.MaterialClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.callback.FunCallInfo;
   import mmo.interfaces.commonpanel.ConfirmPanelParam;
   import mmo.interfaces.commonpanel.ICommonPanelService;
   import mmo.interfaces.material.MaterialTypes;
   import mmo.interfaces.pet.data.petbattleeff.PetBattleDetectHelper;
   import mmo.interfaces.pet.petcommon.GeniusHelper;
   import mmo.interfaces.pet.ui.IPetUIService;
   import mmo.interfaces.secondpwd.ISecondPwdService;
   import mmo.petpackage.controller.helper.AddPetDetailInfoHelper;
   import mmo.play.activity.helper.Pet_Helper;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.commonpanel.item.MaterialObj;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2816")]
   public class PetGeniusInfo extends PetDetailBase
   {
      
      public var btnFull:SimpleButton;
      
      public var btnQuestion:SimpleButton;
      
      public var btnViewDetail:SimpleButton;
      
      public var btnhowgenius:SimpleButton;
      
      public var mcDetail:PetGeniusDetail;
      
      public var mcEffProg:MovieClip;
      
      public var mcgeniusicon:MovieClip;
      
      public var mcgeniusname:MovieClip;
      
      public var txtEff:TextField;
      
      private var petUIService:IPetUIService = null;
      
      private var mcGenius:MovieClip = null;
      
      private var _gdetail:PetGeniusDetail;
      
      private var _btnFull:SimpleButton;
      
      public function PetGeniusInfo()
      {
         super();
      }
      
      override protected function initUI() : void
      {
         this._btnFull = this.getChildByName("btnFull") as SimpleButton;
         AddPetDetailInfoHelper.addDetailInfoMC(2,this,this.setCanUpdate);
         this._gdetail = this.mcDetail as PetGeniusDetail;
         this._gdetail.visible = false;
         ServiceContainer.instance.tryGetService(IPetUIService,function(param1:IPetUIService, param2:Object):void
         {
            petUIService = param1;
            canUpdateUI = true;
            tryRefreshUI();
         });
         this.btnQuestion.addEventListener(MouseEvent.MOUSE_OVER,this.showGeniusDetail);
         this.btnQuestion.addEventListener(MouseEvent.MOUSE_OUT,this.hideGeniusDetail);
         this._btnFull.addEventListener(MouseEvent.CLICK,this.onClickFull);
      }
      
      override public function dispose() : void
      {
         super.dispose();
         this.btnQuestion.removeEventListener(MouseEvent.MOUSE_OVER,this.showGeniusDetail);
         this.btnQuestion.removeEventListener(MouseEvent.MOUSE_OUT,this.hideGeniusDetail);
         if(this._btnFull)
         {
            this._btnFull.removeEventListener(MouseEvent.CLICK,this.onClickFull);
            this._btnFull = null;
         }
      }
      
      private function showGeniusDetail(param1:MouseEvent) : void
      {
         this._gdetail.visible = true;
      }
      
      private function hideGeniusDetail(param1:MouseEvent) : void
      {
         this._gdetail.visible = false;
      }
      
      override protected function refreshUI() : void
      {
         var _loc4_:MovieClip = null;
         var _loc5_:int = 0;
         var _loc1_:int = int(PetBattleDetectHelper.getDetectNumByType(1,pdi));
         var _loc2_:int = int(PetBattleDetectHelper.getMaxNum(pdi,1));
         ActComHelper.setMcProg(ActComHelper.getChildNode(this,"mcEffProg") as MovieClip,[0,_loc2_],[0,50],_loc1_);
         ActComHelper.setTxtValue(this,"txtEff",Math.floor(_loc1_ * 100 / _loc2_) + "%");
         DisplayUtil.stopAndRemove(this.mcGenius);
         if(pdi)
         {
            _loc4_ = this.mcgeniusicon;
            this.mcGenius = this.petUIService.getGeniusIconByPDI(pdi);
            _loc4_.addChild(this.mcGenius);
            _loc5_ = int(GeniusHelper.getGeniusFrameIndex(pdi.ind.arrayData));
            this._gdetail.setInfo(pdi);
         }
         else
         {
            _loc5_ = 7;
         }
         var _loc3_:MovieClip = this.mcgeniusname;
         _loc3_.gotoAndStop(_loc5_);
         this._btnFull.visible = this.pdi != null && Boolean(Pet_Helper.checkPetIsGQPet(this.pdi.raceId));
         TipsManager.getInstance().replaceTips(this._btnFull,"可快捷消耗天赋增强精华提升当前亚比天赋至唯我独尊！（天赋值70）");
      }
      
      private function onClickFull(param1:MouseEvent) : void
      {
         var content:String;
         var self:PetGeniusInfo = null;
         var ITEM_ID:int = 0;
         var needItem:int = 0;
         var param:ConfirmPanelParam = null;
         var sureFullLevel:Function = null;
         var afterVertify:Function = null;
         var evt:MouseEvent = param1;
         sureFullLevel = function():void
         {
            if(needItem > ActComHelper.getItemQuantity(ITEM_ID))
            {
               NotifyQueue.getInstance().add("天赋增强精华不足");
               return;
            }
            var _loc1_:FunCallInfo = new FunCallInfo(afterVertify);
            var _loc2_:ISecondPwdService = ServiceContainer.getService(ISecondPwdService) as ISecondPwdService;
            _loc2_.verify(_loc1_);
         };
         afterVertify = function():void
         {
            ProgressFullSprite.show();
            SocketClient.instance.addEventListener(MaterialClient.cmdUsePetItem,onUseItem);
            MaterialClient.getInstance().useItem(ITEM_ID,self.pdi.id,-1,needItem);
         };
         self = this;
         ITEM_ID = 177;
         if(GeniusHelper.isWeiWoDuZhun(this.pdi.ind.arrayData))
         {
            NotifyQueue.getInstance().add("你的亚比已经达到唯我独尊了！");
            return;
         }
         needItem = this.getNeedItem();
         content = "是否消耗" + needItem + "天赋增强精华分配给" + this.pdi.name + "吗？\n" + "（预计可提升当前亚比天赋至唯我独尊）";
         param = new ConfirmPanelParam();
         param.content = content;
         param.title = "天赋提升";
         param.onSure = sureFullLevel;
         param.todayLocalKey = "PetPackage_FullLevel";
         param.itemArray = [new MaterialObj(MaterialTypes.ITEM,ITEM_ID,needItem)];
         ServiceContainer.tryGetService(ICommonPanelService,function(param1:ICommonPanelService, param2:Object):void
         {
            ProgressFullSprite.close();
            param1.showConfirmPanel(param);
         });
      }
      
      private function onUseItem(param1:SocketClientEvent) : void
      {
         SocketClient.instance.removeEventListener(MaterialClient.cmdUsePetItem,this.onUseItem);
         ProgressFullSprite.close();
         if(param1.params.res == 1)
         {
            PetClient.instance.viewSinglePM(this.pdi.id);
         }
         else
         {
            NewDialog.showMessage("失败");
         }
      }
      
      private function getNeedItem() : int
      {
         return Math.ceil((420 - GeniusHelper.getGeniusSum(this.pdi.ind.arrayData)) / 3);
      }
   }
}

