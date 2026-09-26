package mmo.petpackage.panel.inclusion
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.act_operation.PetFunctionShortcut;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.data.PetDetailDataMap;
   import mmo.petpackage.panel.inclusion.petlist.PetSingleIconBase;
   import mmo.petpackage.service.PetPackageService;
   import mmo.play.actthings.helper.ActComHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol3021")]
   public class PetList extends Sprite implements IDispose
   {
      
      public var pet_0:单只亚比主PetSingleIconBase;
      
      public var pet_1:单只亚比副PetSingleIconBase;
      
      public var pet_2:单只亚比副PetSingleIconBase;
      
      public var pet_3:单只亚比副PetSingleIconBase;
      
      public var pet_4:单只亚比副PetSingleIconBase;
      
      public var pet_5:单只亚比副PetSingleIconBase;
      
      private var _objs:Array = null;
      
      private var pets:Array = null;
      
      private var _selectedPet:PetSingleIconBase = null;
      
      private var ipds:IPetDataService = null;
      
      private var tempPBI:PetBriefInfo = null;
      
      private var _mcPetIconFullScreen:MovieClip;
      
      public function PetList()
      {
         super();
         this.initPars();
         this.initFuns();
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onPMDetailUpdate);
      }
      
      public function setMcPetIconFullScreen(param1:MovieClip) : void
      {
         var _loc3_:MovieClip = null;
         var _loc4_:TextField = null;
         this._mcPetIconFullScreen = param1;
         var _loc2_:int = 0;
         while(_loc2_ < 6)
         {
            _loc3_ = this._mcPetIconFullScreen.getChildByName("mcPet_" + _loc2_) as MovieClip;
            _loc3_.buttonMode = true;
            _loc3_.addEventListener(MouseEvent.CLICK,this.onClickFull);
            _loc4_ = _loc3_.getChildByName("txtPetName") as TextField;
            _loc4_.mouseEnabled = false;
            _loc2_++;
         }
      }
      
      private function refreshMcPetIconFullScreen() : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:PetBriefInfo = null;
         var _loc1_:int = 0;
         while(_loc1_ < 6)
         {
            _loc2_ = this._mcPetIconFullScreen.getChildByName("mcPet_" + _loc1_) as MovieClip;
            _loc2_.visible = this._objs != null && this._objs.length > _loc1_;
            if(this._objs != null && this._objs.length > _loc1_)
            {
               _loc3_ = new PetBriefInfo();
               _loc3_.parseInfo(this._objs[_loc1_]);
               ActComHelper.setTxtValue(_loc2_,"txtPetName",_loc3_.name);
               ActComHelper.setMcFrame(_loc2_.parent,_loc2_.name,(this.pets[_loc1_] as PetSingleIconBase).selected ? 2 : 1);
            }
            _loc1_++;
         }
      }
      
      private function initPars() : void
      {
         this.pets = [this.pet_0,this.pet_1,this.pet_2,this.pet_3,this.pet_4,this.pet_5];
         this.ipds = ServiceContainer.getService(IPetDataService) as IPetDataService;
         this.tempPBI = new PetBriefInfo();
      }
      
      private function initFuns() : void
      {
         var _loc2_:PetSingleIconBase = null;
         var _loc1_:int = int(this.pets.length - 1);
         while(_loc1_ >= 0)
         {
            _loc2_ = this.pets[_loc1_] as PetSingleIconBase;
            _loc2_.buttonMode = true;
            _loc2_.addEventListener(MouseEvent.CLICK,this.onClick);
            _loc1_--;
         }
      }
      
      public function refresh2First() : void
      {
         this.refreshUI();
         this.setSelected(true);
      }
      
      public function refreshCurrent() : void
      {
         this.refreshUI();
         this.setSelected(false);
      }
      
      public function setSelcectPetById(param1:int) : void
      {
         var _loc4_:PetSingleIconBase = null;
         var _loc2_:int = this.getPid(param1);
         if(_loc2_ == -1)
         {
            return;
         }
         var _loc3_:int = 0;
         while(_loc3_ < this.pets.length)
         {
            _loc4_ = this.pets[_loc3_] as PetSingleIconBase;
            if(_loc4_.id == _loc2_)
            {
               this.refreshUI();
               this.setSelectedPet(this.pets[_loc3_],true);
            }
            _loc3_++;
         }
      }
      
      private function getPid(param1:int) : int
      {
         var _loc2_:int = 0;
         while(_loc2_ < this._objs.length)
         {
            if(param1 == this._objs[_loc2_].pmSView.f)
            {
               return this._objs[_loc2_].pmSView.i;
            }
            _loc2_++;
         }
         return -1;
      }
      
      public function setData(param1:Array) : void
      {
         this.disposeFuns();
         this._objs = param1;
         this.initFuns();
      }
      
      public function get selectedPet() : PetSingleIconBase
      {
         return this._selectedPet;
      }
      
      public function dispose() : void
      {
         var _loc1_:PetSingleIconBase = null;
         var _loc2_:int = 0;
         var _loc3_:MovieClip = null;
         for each(_loc1_ in this.pets)
         {
            _loc1_.buttonMode = false;
            _loc1_.removeEventListener(MouseEvent.CLICK,this.onClick);
            _loc1_.dispose();
         }
         _loc2_ = 0;
         while(_loc2_ < 6)
         {
            _loc3_ = this._mcPetIconFullScreen.getChildByName("mcPet_" + _loc2_) as MovieClip;
            _loc3_.removeEventListener(MouseEvent.CLICK,this.onClickFull);
            _loc2_++;
         }
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onPMDetailUpdate);
      }
      
      private function refreshUI() : void
      {
         var _loc2_:PetSingleIconBase = null;
         var _loc1_:int = 0;
         while(_loc1_ < this.pets.length)
         {
            _loc2_ = this.pets[_loc1_] as PetSingleIconBase;
            if(_loc1_ < this._objs.length)
            {
               _loc2_.setData(this._objs[_loc1_]);
            }
            else
            {
               _loc2_.nullPet();
            }
            _loc1_++;
         }
         this.refreshMcPetIconFullScreen();
      }
      
      private function setSelected(param1:Boolean) : void
      {
         if(null != this.pets && this.pets.length >= 1)
         {
            if(param1)
            {
               this.setSelectedPet(this.pets[0],true);
            }
            else
            {
               this.setSelectedPet(this._selectedPet,true);
            }
         }
      }
      
      private function disposeFuns() : void
      {
         var _loc1_:PetSingleIconBase = null;
         for each(_loc1_ in this.pets)
         {
            _loc1_.buttonMode = false;
            _loc1_.removeEventListener(MouseEvent.CLICK,this.onClick);
         }
      }
      
      private function onClickFull(param1:Object) : void
      {
         var _loc2_:int = int(param1.currentTarget.name.split("_")[1]);
         var _loc3_:PetSingleIconBase = this.pets[_loc2_];
         if(_loc3_.id > 0)
         {
            this.setSelectedPet(_loc3_);
         }
         else
         {
            PetPackageService.currentPanel.closePanel();
            PetFunctionShortcut.tryOpenPetStore();
         }
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:PetSingleIconBase = param1.currentTarget as PetSingleIconBase;
         if(_loc2_.id > 0)
         {
            this.setSelectedPet(_loc2_);
         }
         else
         {
            PetPackageService.currentPanel.closePanel();
            PetFunctionShortcut.tryOpenPetStore();
         }
      }
      
      private function onPMDetailUpdate(param1:PetPackageEvent) : void
      {
         this.refreshUI();
      }
      
      private function setSelectedPet(param1:PetSingleIconBase, param2:Boolean = false) : void
      {
         if(null == param1 || this._selectedPet == param1 && !param2)
         {
            return;
         }
         if(null != this._selectedPet)
         {
            this._selectedPet.selected = false;
         }
         this._selectedPet = param1;
         this._selectedPet.selected = true;
         this.tempPBI.parseInfo(this._selectedPet.objData);
         this.ipds.setSelectPetId(this.tempPBI.id);
         PetDetailDataMap.instance.saveCurrentPet(this.tempPBI.id);
         PetDetailDataMap.instance.tryUpdateCachhe(this.tempPBI.id);
      }
   }
}

