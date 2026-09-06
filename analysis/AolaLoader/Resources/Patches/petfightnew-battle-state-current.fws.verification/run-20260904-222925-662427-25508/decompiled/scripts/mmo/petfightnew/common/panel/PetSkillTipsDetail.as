package mmo.petfightnew.common.panel
{
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.petfightnew.common.manager.ServicePool;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol440")]
   public class PetSkillTipsDetail extends Sprite
   {
      
      public var nameText:TextField;
      
      public var powerText:TextField;
      
      public var ppText:TextField;
      
      private var _txtName:TextField;
      
      private var _txtPower:TextField;
      
      private var _txtPP:TextField;
      
      public function PetSkillTipsDetail()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         this._txtName = this.getChildByName("nameText") as TextField;
         this._txtName.mouseEnabled = false;
         this._txtPower = this.getChildByName("powerText") as TextField;
         this._txtPower.mouseEnabled = false;
         this._txtPP = this.getChildByName("ppText") as TextField;
         this._txtPP.mouseEnabled = false;
      }
      
      public function update(param1:SkillInfo) : void
      {
         var _loc2_:IPetSkillMesService = ServicePool.instance.getService(IPetSkillMesService);
         var _loc3_:Object = _loc2_.getPetSkillMes(param1.id);
         this._txtName.text = param1.name;
         this._txtPower.text = _loc3_.power > 0 ? int(_loc3_.power).toString() : "-";
         this._txtPP.text = param1.canUseTimes + "/" + param1.maxUseTimes;
      }
   }
}

