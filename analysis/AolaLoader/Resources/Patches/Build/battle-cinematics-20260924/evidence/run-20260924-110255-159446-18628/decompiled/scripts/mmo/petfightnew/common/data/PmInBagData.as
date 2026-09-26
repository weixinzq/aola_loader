package mmo.petfightnew.common.data
{
   import mmo.play.actthings.helper.ActComHelper;
   
   public class PmInBagData
   {
      
      private var _pmid:int;
      
      private var _maxHp:int;
      
      private var _curHp:int;
      
      private var _uqi:int;
      
      private var _st:String;
      
      private var _lockRound:int;
      
      private var _raceId:int;
      
      private var _viewId:int;
      
      private var _name:String;
      
      private var _nickName:String;
      
      private var _pmAttribute:int;
      
      private var _pmAttribute2:int;
      
      public function PmInBagData()
      {
         super();
      }
      
      public function get pmid() : int
      {
         return this._pmid;
      }
      
      public function get maxHp() : int
      {
         return this._maxHp;
      }
      
      public function get curHp() : int
      {
         return this._curHp;
      }
      
      public function get uqi() : int
      {
         return this._uqi;
      }
      
      public function get st() : String
      {
         return this._st;
      }
      
      public function get lockRound() : int
      {
         return this._lockRound;
      }
      
      public function set lockRound(param1:int) : void
      {
         this._lockRound = param1;
      }
      
      public function get raceId() : int
      {
         return this._raceId;
      }
      
      public function get viewId() : int
      {
         return this._viewId;
      }
      
      public function get name() : String
      {
         return this._name;
      }
      
      public function get nickName() : String
      {
         return this._nickName;
      }
      
      public function get pmAttribute() : int
      {
         return this._pmAttribute;
      }
      
      public function get pmAttribute2() : int
      {
         return this._pmAttribute2;
      }
      
      public function setData(param1:Object) : *
      {
         this._pmid = ActComHelper.tryGetPro(param1,"i",this._pmid);
         this._maxHp = ActComHelper.tryGetPro(param1,"s0",this._maxHp);
         this._curHp = ActComHelper.tryGetPro(param1,"c0",this._curHp);
         this._uqi = ActComHelper.tryGetPro(param1,"uqi",this._uqi);
         this._st = ActComHelper.tryGetPro(param1,"st",this._st);
         this._lockRound = ActComHelper.tryGetPro(param1,"lock",this._lockRound);
         this._raceId = ActComHelper.tryGetPro(param1,"r",this._raceId);
         this._viewId = ActComHelper.tryGetPro(param1,"f",this._viewId);
         this._name = ActComHelper.tryGetPro(param1,"nm",this._name);
         this._nickName = ActComHelper.tryGetPro(param1,"nick",this._nickName);
         this._pmAttribute = ActComHelper.tryGetPro(param1,"t",this._pmAttribute);
         this._pmAttribute2 = ActComHelper.tryGetPro(param1,"t1",this._pmAttribute2);
      }
   }
}

