package mmo.petpackage.service
{
   import flash.events.EventDispatcher;
   import mmo.common.ProgressFullSprite;
   import mmo.common.movieplayer.MovieMaster;
   import mmo.common.shareobject.LocalStore;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.callback.FunCallInfo;
   import mmo.interfaces.newbie.NewbieEvent;
   import mmo.interfaces.newbie.NewbieEventDispatcher;
   import mmo.interfaces.pet.petpackage.IPetPackageService;
   import mmo.loader.common.datastructures.ResourceObject;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.controller.helper.TabJumpHelper;
   import mmo.petpackage.data.PetDetailDataMap;
   import mmo.petpackage.panel.PetPackagePanel;
   import mmo.play.activity.framework.util.LinkUtil;
   
   public class PetPackageService extends EventDispatcher implements IPetPackageService
   {
      
      private static var petPackagePanel:PetPackagePanel = null;
      
      private static const Key:String = "20150106cleareff";
      
      public function PetPackageService()
      {
         super();
      }
      
      public static function get currentPanel() : PetPackagePanel
      {
         return petPackagePanel;
      }
      
      public function init() : void
      {
      }
      
      public function showPanel() : void
      {
         if(null != petPackagePanel)
         {
            return;
         }
         this.showPackage();
      }
      
      private function tryShowFirstMovie() : void
      {
         var _loc1_:ResourceObject = null;
         if(LocalStore.getAndSetFlag(Key))
         {
            this.showPackage();
         }
         else
         {
            _loc1_ = new ResourceObject("pet/petpackage/firstmovie","mmo.petpackage_res.movie.FirstMovie");
            MovieMaster.loadShowMovie(_loc1_,new FunCallInfo(this.showPackage,this,null));
         }
      }
      
      private function showPackage() : void
      {
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(PetClient.RSPN_VIEW_ALL_PM,this.onAllPMUpdate);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_SERVICE_DISPOSE,this.onServiceDispose);
         petPackagePanel = new PetPackagePanel();
         this.getData();
      }
      
      public function closePanel() : void
      {
         if(petPackagePanel != null)
         {
            petPackagePanel.closePanel();
            petPackagePanel = null;
         }
      }
      
      public function changeFirstTab(param1:int) : void
      {
         TabJumpHelper.changeFirstTab(param1);
      }
      
      public function changeSecondTab(param1:int) : void
      {
         TabJumpHelper.changeSecondTab(param1);
      }
      
      public function changeToTargetTab(param1:Array) : void
      {
         TabJumpHelper.changeFirstTab(param1[0]);
         TabJumpHelper.changeSecondTab(param1[1]);
      }
      
      private function getData() : void
      {
         SocketClient.instance.addEventListener(PetClient.RSPN_YU_SHE_VIEW_ALL_PM,this.onYuSheAllPM);
         SocketClient.instance.addEventListener(PetClient.RSPN_ADD_DELETE_LINEUP,this.onYuSheChange);
         SocketClient.instance.addEventListener(PetClient.RSPN_VIEW_ALL_PM,this.onViewAllPM);
         PetClient.instance.viewAllPM();
      }
      
      private function onYuSheAllPM(param1:SocketClientEvent) : void
      {
         if(param1.params.msg == null)
         {
            this.onViewAllPM(param1);
         }
         else
         {
            ProgressFullSprite.close();
         }
      }
      
      private function onYuSheChange(param1:SocketClientEvent) : void
      {
         var _loc2_:Array = null;
         ProgressFullSprite.close();
         if(param1.params.r == 1)
         {
            _loc2_ = LinkUtil.reNamePmListName(param1.params.prv);
            petPackagePanel.setYuSheList(_loc2_);
            petPackagePanel.showPanel();
         }
      }
      
      private function onViewAllPM(param1:SocketClientEvent) : void
      {
         var _loc7_:Object = null;
         var _loc8_:Array = null;
         var _loc9_:Array = null;
         var _loc10_:int = 0;
         SocketClient.instance.removeEventListener(PetClient.RSPN_VIEW_ALL_PM,this.onViewAllPM);
         PetDetailDataMap.instance;
         ProgressFullSprite.close();
         var _loc2_:String = param1.params.pms;
         var _loc3_:Array = param1.params.pmList;
         var _loc4_:int = int(param1.params.cui);
         var _loc5_:Array = _loc2_.split("#");
         var _loc6_:Array = [];
         _loc6_.length = _loc3_.length;
         for each(_loc7_ in _loc3_)
         {
            _loc10_ = int(_loc5_.indexOf("" + _loc7_.pmSView.i));
            _loc6_[_loc10_] = _loc7_;
         }
         _loc8_ = LinkUtil.reNamePmListName(param1.params.prv);
         _loc9_ = param1.params.prv;
         petPackagePanel.setData(_loc6_,_loc4_,_loc9_);
         petPackagePanel.showPanel();
      }
      
      private function onAllPMUpdate(param1:SocketClientEvent) : void
      {
         var _loc6_:Object = null;
         var _loc7_:int = 0;
         var _loc8_:Array = null;
         var _loc9_:Array = null;
         var _loc10_:int = 0;
         PetDetailDataMap.instance.cleanAllCache();
         var _loc2_:String = param1.params.pms;
         if(_loc2_ == null)
         {
            return;
         }
         var _loc3_:Array = param1.params.pmList;
         var _loc4_:Array = _loc2_.split("#");
         var _loc5_:Array = [];
         _loc5_.length = _loc3_.length;
         for each(_loc6_ in _loc3_)
         {
            _loc10_ = int(_loc4_.indexOf("" + _loc6_.pmSView.i));
            _loc5_[_loc10_] = _loc6_;
         }
         _loc7_ = int(param1.params.cui);
         _loc8_ = LinkUtil.reNamePmListName(param1.params.prv);
         _loc9_ = param1.params.prv;
         petPackagePanel.setData(_loc5_,_loc7_,_loc8_);
         petPackagePanel.updateData(_loc5_,_loc7_,_loc8_);
      }
      
      private function onServiceDispose(param1:PetPackageEvent) : void
      {
         this.disposeEvent();
      }
      
      private function disposeEvent() : void
      {
         SocketClient.instance.removeEventListener(PetClient.RSPN_VIEW_ALL_PM,this.onAllPMUpdate);
         SocketClient.instance.removeEventListener(PetClient.RSPN_VIEW_ALL_PM,this.onViewAllPM);
         SocketClient.instance.removeEventListener(PetClient.RSPN_YU_SHE_VIEW_ALL_PM,this.onYuSheAllPM);
         SocketClient.instance.removeEventListener(PetClient.RSPN_ADD_DELETE_LINEUP,this.onYuSheChange);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_SERVICE_DISPOSE,this.onServiceDispose);
         NewbieEventDispatcher.getInstance().dispatchEvent(new NewbieEvent(NewbieEvent.ON_CLOSE_YABI_PACKAGE,{}));
         PetDetailDataMap.instance.dispose();
         PetPackageEventDispatcher.instance.dispose();
         this.closePanel();
      }
   }
}

