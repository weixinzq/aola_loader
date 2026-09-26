package mmo.petpackage.panel.inclusion
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.activity.helper.Pet_Helper;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.actthings.helper.ActTipsMc;
   
   public class GQPetPreset implements IDispose
   {
      
      private var isDisposed:Boolean = false;
      
      private var canUpdateUI:Boolean = false;
      
      private var _view:MovieClip;
      
      private var _tips:DisplayObject;
      
      private var _ipds:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
      
      private var _currentFirstTab:int;
      
      public function GQPetPreset(param1:MovieClip)
      {
         super();
         this._view = param1;
         this.init();
      }
      
      private function init() : void
      {
         this.initTips();
         this.initListeners();
      }
      
      private function initTips() : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function onLoadedTips() : void
      {
         new ActTipsMc().init(ActComHelper.getChildNode(this._view,"btnViewAll"),this._tips);
         TipsManager.getInstance().replaceTips(this._view,"点击编辑快捷配置");
      }
      
      private function initListeners() : void
      {
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_INFO_TAB_CHANGED,this.onChangeFirstTab);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onDetailUpdate);
         CommonEventDispatcher.instance.addEventListener(CommonEvent.ON_CAI_DAN_SKIN_RESET,this.onResetSkin);
         var _loc1_:SimpleButton = ActComHelper.getChildNode(this._view,"btnViewAll") as SimpleButton;
         _loc1_.addEventListener(MouseEvent.CLICK,this.onClickViewAll);
      }
      
      private function onClickViewAll(param1:MouseEvent) : void
      {
         Panel_Helper.loadResAndShow("activityres/activity251107/guangqipetpreset/guangqipetpreset_code","mmo.activity251107.guangqipetpreset.panel.GQPP_MainPl");
      }
      
      private function onResetSkin(param1:CommonEvent) : void
      {
         this._tips.parent.setChildIndex(this._tips,this._tips.parent.numChildren - 1);
      }
      
      private function onDetailUpdate(param1:PetPackageEvent) : void
      {
         var _loc2_:int = int(this._ipds.getSelectPetId());
         if(param1.params.id == _loc2_)
         {
            this.refresh();
         }
      }
      
      private function onChangeFirstTab(param1:PetPackageEvent) : void
      {
         this._currentFirstTab = param1.params.firstTab;
         this.refresh();
      }
      
      private function refresh() : void
      {
         this._view.visible = this._currentFirstTab == 0 && Boolean(Pet_Helper.checkPetIsGQPet(this._ipds.getPetByPetId(this._ipds.getSelectPetId()).raceId));
      }
      
      public function dispose() : void
      {
         this.isDisposed = true;
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_INFO_TAB_CHANGED,this.onChangeFirstTab);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onDetailUpdate);
         CommonEventDispatcher.instance.removeEventListener(CommonEvent.ON_CAI_DAN_SKIN_RESET,this.onResetSkin);
         var _loc1_:SimpleButton = ActComHelper.getChildNode(this._view,"btnViewAll") as SimpleButton;
         if(_loc1_)
         {
            _loc1_.removeEventListener(MouseEvent.CLICK,this.onClickViewAll);
         }
         if(this._tips != null)
         {
            if(this._tips.parent)
            {
               this._tips.parent.removeChild(this._tips);
            }
            IDispose(this._tips).dispose();
            this._tips = null;
         }
      }
   }
}

