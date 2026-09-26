package mmo.petpackage.controller.reddot
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import mmo.common.shareobject.LocalStore;
   import mmo.framework.comm.Commands;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.pet.petpackage.NeedNoticeMaterialList;
   import mmo.interfaces.pet.petpackage.PetPackageTabs;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   
   public class ItemTabRedDotHandler implements IDispose
   {
      
      private static const LOCAL_KEY:String = "PetPackage_ShowItemTabRedDot";
      
      private const ITEM_SERVICE:IItemService = ServiceContainer.getService(IItemService) as IItemService;
      
      private var _redDotMc:MovieClip;
      
      private var _tabIndex:int = -1;
      
      private var _needShow:Boolean = false;
      
      public function ItemTabRedDotHandler(param1:DisplayObject, param2:int = -1)
      {
         super();
         this._redDotMc = MovieClip(param1);
         this._redDotMc.mouseChildren = false;
         this._redDotMc.mouseEnabled = false;
         this._tabIndex = param2;
         this.initListener();
         this.onItemDataUpdateListener();
      }
      
      private function initListener() : void
      {
         SocketClient.instance.addEventListener(Commands.cmd_notify_amount_update,this.onItemDataUpdateListener);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_INFO_TAB_CHANGED,this.onTabChange);
      }
      
      private function onItemDataUpdateListener(param1:SocketClientEvent = null) : void
      {
         this._needShow = false;
         if(LocalStore.getFlag(LOCAL_KEY))
         {
            this.refreshView();
            return;
         }
         var _loc2_:int = 0;
         while(_loc2_ < NeedNoticeMaterialList.NOTICE_ITEM_LIST.length)
         {
            if(this.ITEM_SERVICE.getMyItemQuantity(NeedNoticeMaterialList.NOTICE_ITEM_LIST[_loc2_].id) >= NeedNoticeMaterialList.NOTICE_ITEM_LIST[_loc2_].quantity)
            {
               this._needShow = true;
               break;
            }
            _loc2_++;
         }
         this.refreshView();
      }
      
      private function onTabChange(param1:PetPackageEvent) : void
      {
         if(!this._needShow)
         {
            return;
         }
         var _loc2_:int = int(param1.params.firstTab);
         var _loc3_:int = int(param1.params.secondTab);
         this._tabIndex = _loc2_;
         if(_loc2_ == PetPackageTabs.TAB_ITEM[0] && _loc3_ == PetPackageTabs.TAB_ITEM[1] && this._needShow)
         {
            LocalStore.getAndSetFlag(LOCAL_KEY);
            this._needShow = false;
         }
         this.refreshView();
      }
      
      public function setTab(param1:int) : void
      {
         this._tabIndex = param1;
         this.refreshView();
      }
      
      private function refreshView() : void
      {
         if(this._redDotMc)
         {
            this._redDotMc.visible = this._tabIndex == 0 && this._needShow;
         }
      }
      
      public function dispose() : void
      {
         SocketClient.instance.removeEventListener(Commands.cmd_notify_amount_update,this.onItemDataUpdateListener);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_INFO_TAB_CHANGED,this.onTabChange);
      }
   }
}

